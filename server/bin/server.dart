import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dotenv/dotenv.dart';
import 'package:logging/logging.dart';
import 'package:rfc_6901/rfc_6901.dart';
import 'package:server/socket_messages.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_gzip/shelf_gzip.dart';
import 'package:shelf_multipart/shelf_multipart.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:snout_db/patch.dart';
import 'package:snout_db/snout_db.dart';
import 'package:synchronized/synchronized.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'edit_lock.dart';

//TODO implement https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/ETag

final env = DotEnv(includePlatformEnvironment: true);
int serverPort = 6749;
Map<String, EventData> loadedEvents = {};

//To keep things simple we will just have 1 edit lock for all loaded events.
EditLock editLock = EditLock();

// used to prevent the server from writing the database multiple times at once
final Lock dbWriteLock = Lock();

final app = Router();

final Logger logger = Logger("snout-scout-server");

final eventsDirectory = Directory('events');

//Stuff that should be done for each event that is loaded.
class EventData {
  EventData(this.file);

  List<({String identity, String status, DateTime time})> scoutStatus = [];

  void sendScoutStatusToListeners() {
    for (final listener in listeners) {
      listener.sink.add(
        json.encode({
          "type": SocketMessageType.scoutStatus,
          "value": [
            for (final status in scoutStatus)
              {
                "identity": status.identity,
                "status": status.status,
                "time": status.time.toIso8601String(),
              },
          ],
        }),
      );
    }
  }

  File file;
  List<WebSocketChannel> listeners = [];
}

//Load all events from disk and instantiate an event data class for each one
Future loadEvents() async {
  final List<FileSystemEntity> allEvents =
      await eventsDirectory.list().toList();
  for (final event in allEvents) {
    if (event is File) {
      logger.info(event.uri.pathSegments.last);
      loadedEvents[event.uri.pathSegments.last] = EventData(event);
    }
  }
}

void main(List<String> args) async {
  logger.onRecord.listen((event) {
    // ignore: avoid_print
    print(
      '${event.level}: ${event.message} ${event.error ?? ''} ${event.stackTrace ?? ''}',
    );
  });

  env.load();

  // Create the events directory if it does not exist
  eventsDirectory.create();

  await loadEvents();

  app.get("/listen/<event>", (Request request, String event) {
    event = Uri.decodeComponent(event);
    final handler = webSocketHandler(
      (WebSocketChannel webSocket, _) {
        logger.info('new listener for $event');
        webSocket.sink.done
            .then((value) => loadedEvents[event]?.listeners.remove(webSocket));
        loadedEvents[event]?.listeners.add(webSocket);
        loadedEvents[event]?.sendScoutStatusToListeners();

        webSocket.stream.listen((message) {
          try {
            final decoded =
                json.decode(message as String) as Map<String, dynamic>;
            logger.fine("got socket message");

            switch (decoded['type'] as String) {
              case SocketMessageType.scoutStatusUpdate:
                //remove old status
                loadedEvents[event]?.scoutStatus.removeWhere(
                      (element) => element.identity == decoded['identity'],
                    );
                loadedEvents[event]?.scoutStatus.removeWhere(
                      (element) =>
                          DateTime.now().difference(element.time).inMinutes > 9,
                    );
                loadedEvents[event]?.scoutStatus.add(
                  (
                    identity: decoded['identity'],
                    status: decoded['value'],
                    time: DateTime.now().toUtc()
                  ),
                );
                loadedEvents[event]
                    ?.scoutStatus
                    .sort((a, b) => a.identity.compareTo(b.identity));

                loadedEvents[event]?.sendScoutStatusToListeners();
            }
          } catch (e, s) {
            logger.severe("failed to handle socket message", e, s);
          }
        });
      },
      pingInterval: const Duration(hours: 8),
    );

    return handler(request);
  });

  app.get("/edit_lock", (Request request) {
    final key = request.headers["key"];
    if (key == null) {
      return Response.badRequest(body: "invalid or missing key");
    }
    final lock = editLock.get(key);
    return Response.ok(lock.toString());
  });

  app.post("/edit_lock", (Request request) {
    final key = request.headers["key"];
    if (key == null) {
      return Response.badRequest(body: "invalid or missing key");
    }
    editLock.set(key);
    return Response.ok("");
  });

  app.delete("/edit_lock", (Request request) {
    final key = request.headers["key"];
    if (key == null) {
      return Response.badRequest(body: "invalid or missing key");
    }
    editLock.clear(key);
    return Response.ok("");
  });

  app.put("/upload_events", (Request request) {
    // Since this edits db files, it could conflict with other writes
    return dbWriteLock.synchronized(() async {
      if ((request.headers['upload_password'] ?? '') !=
          env.getOrElse("upload_password", () => '')) {
        return Response.unauthorized("upload_password is invalid");
      }

      if (request.formData() case final form?) {
        await for (final entry in form.formData) {
          // Headers are available through part.headers as a map:
          final part = entry.part;
          final fileName = entry.name;

          logger.info("Attempting file upload for event name $fileName");
          final eventFile = File('${eventsDirectory.path}/$fileName');
          // We will overrwrite automatically

          final fileContent = await part.readBytes();

          // Write file to disk and flush
          eventFile.writeAsBytes(fileContent, flush: true);

          // Load the event in-place. This might not need to be done in the future
          loadedEvents[fileName] = EventData(eventFile);
        }
      }
      return Response.ok("upload success");
    });
  });

  /// Just accept any files that are uploaded assuming the password is provided
  app.delete("/events/<eventID>", (Request request, String eventID) {
    eventID = Uri.decodeComponent(eventID);
    // Since this edits db files, it could conflict with other writes
    return dbWriteLock.synchronized(() async {
      if ((request.headers['upload_password'] ?? '') !=
          env.getOrElse("upload_password", () => '')) {
        return Response.unauthorized("upload_password is invalid");
      }

      logger.info("Attempting file upload for event name $eventID");
      final eventFile = File('${eventsDirectory.path}/$eventID');

      // unload the file
      loadedEvents.removeWhere((key, value) => key == eventID);
      // delete from disk
      await eventFile.delete();

      return Response.ok("delete success");
    });
  });

  app.get("/events", (Request request) {
    return Response.ok(
      json.encode(loadedEvents.keys.toList()),
      headers: {
        'Content-Type':
            ContentType('application', 'json', charset: 'utf-8').toString(),
      },
    );
  });

  app.get("/events/<eventID>", (Request request, String eventID) async {
    eventID = Uri.decodeComponent(eventID);

    final File? f = loadedEvents[eventID]?.file;
    if (f == null || await f.exists() == false) {
      return Response.notFound("Event not found");
    }
    final event = SnoutDB.fromJson(
      json.decode(await f.readAsString()) as Map<String, dynamic>,
    );

    return Response.ok(
      json.encode(event),
      headers: {
        'Content-Type':
            ContentType('application', 'json', charset: 'utf-8').toString(),
      },
    );
  });

  app.get("/events/<eventID>/patchDiff",
      (Request request, String eventID) async {
    eventID = Uri.decodeComponent(eventID);
    final File? f = loadedEvents[eventID]?.file;
    if (f == null || await f.exists() == false) {
      return Response.notFound("Event not found");
    }
    final event = SnoutDB.fromJson(
      json.decode(await f.readAsString()) as Map<String, dynamic>,
    );

    final clientHead = request.headers["head"];
    if (clientHead == null) {
      return Response(406, body: "send head");
    }
    final int clientHeadInt = int.parse(clientHead);

    if (clientHeadInt < 1) {
      return Response(406, body: 'head cannot be less than 1');
    }

    final range = event.patches.getRange(clientHeadInt, event.patches.length);

    return Response.ok(
      json.encode(range.toList()),
      headers: {
        'Content-Type':
            ContentType('application', 'json', charset: 'utf-8').toString(),
      },
    );
  });

  app.get("/events/<eventID>/<subPath|.*>",
      (Request request, String eventID, String subPath) async {
    eventID = Uri.decodeComponent(eventID);
    final File? f = loadedEvents[eventID]?.file;
    if (f == null || await f.exists() == false) {
      return Response.notFound("Event not found");
    }
    final event = SnoutDB.fromJson(
      json.decode(await f.readAsString()) as Map<String, dynamic>,
    );

    try {
      var dbJson = json.decode(json.encode(event));
      final pointer = JsonPointer('/$subPath');
      dbJson = pointer.read(dbJson);
      return Response.ok(
        json.encode(dbJson),
        headers: {
          'Content-Type':
              ContentType('application', 'json', charset: 'utf-8').toString(),
        },
      );
    } catch (e, s) {
      logger.warning('failed to read sub-path', e, s);
      return Response.internalServerError(body: e);
    }
  });

  app.put(
    "/events/<eventID>",
    (Request request, String eventID) {
      eventID = Uri.decodeComponent(eventID);
      // Require all writes to start with reading the file, only one at a time and do a full disk flush
      return dbWriteLock.synchronized(() async {
        final File? f = loadedEvents[eventID]?.file;
        if (f == null || await f.exists() == false) {
          return Response.notFound("Event not found");
        }
        final event = SnoutDB.fromJson(
          json.decode(await f.readAsString()) as Map<String, dynamic>,
        );
        //Uses UTF-8 by default
        final String content = await request.readAsString();
        try {
          final Patch patch = Patch.fromJson(json.decode(content) as Map);

          event.addPatch(patch);

          logger.fine('added patch: ${json.encode(patch)}');

          //Successful patch, send this update to all listeners
          for (final WebSocketChannel listener
              in loadedEvents[eventID]?.listeners ?? []) {
            listener.sink.add(
              json.encode({
                "type": SocketMessageType.newPatch,
                "patch": patch.toJson(),
              }),
            );
          }

          //Write the new DB to disk
          await f.writeAsString(json.encode(event), flush: true);

          return Response.ok("");
        } catch (e, s) {
          logger.severe('failed to accept patch: $content', e, s);
          return Response.internalServerError(body: e);
        }
      });
    },
  );

  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(handleCORS())
      .addMiddleware(gzipMiddleware)
      .addHandler(app.call);

  final HttpServer server = await shelf_io.serve(
    handler,
    InternetAddress.anyIPv4,
    serverPort,
    poweredByHeader: 'frogs',
  );
  //Enable GZIP compression since every byte counts and the performance hit is
  //negligable for the 30%+ compression depending on how much of the data is image
  server.autoCompress = true;
  //TODO i think this will work if chunked transfer encoding is set..

  logger.info('Server started: ${server.address} port ${server.port}');
}

Middleware handleCORS() => (innerHandler) {
      return (request) async {
        final Map<String, String> headers = {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Headers': '*',
          'Access-Control-Allow-Methods': '*',
          'Access-Control-Request-Method': '*',
        };

        if (request.method == "OPTIONS") {
          return Response.ok("", headers: headers);
        }

        final res = await innerHandler(request);
        return res.change(headers: headers);
      };
    };
