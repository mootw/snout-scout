import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cbor/cbor.dart';
import 'package:collection/collection.dart';
import 'package:dotenv/dotenv.dart';
import 'package:logging/logging.dart';
import 'package:server/socket_messages.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_gzip/shelf_gzip.dart';
import 'package:shelf_multipart/shelf_multipart.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:snout_db/message.dart';
import 'package:snout_db/snout_chain.dart';
import 'package:synchronized/synchronized.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'edit_lock.dart';

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

  File file;
  List<WebSocketChannel> listeners = [];
}

//Load all events from disk and instantiate an event data class for each one
Future _loadEvents() async {
  final List<FileSystemEntity> allEvents = await eventsDirectory
      .list()
      .toList();
  for (final event in allEvents) {
    if (event is File) {
      logger.info(event.uri.pathSegments.last);
      loadedEvents[event.uri.pathSegments.last] = EventData(event);
    }
  }
}

Future<SnoutDBFile?> _loadFromDisk(String eventID) async {
  final File? f = loadedEvents[eventID]?.file;
  if (f == null || await f.exists() == false) {
    return null;
  }
  return SnoutDBFile.fromCbor(cbor.decode(await f.readAsBytes()) as CborMap);
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

  await _loadEvents();

  Timer.periodic(const Duration(seconds: 25), (_) {
    for (final event in loadedEvents.entries) {
      for (final listener in event.value.listeners) {
        try {
          listener.sink.add("PING");
        } catch (e) {
          // logger.info("failed to ping");
        }
      }
    }
  });

  app.get("/listen/<event>", (Request request, String event) {
    event = Uri.decodeComponent(event);
    final handler = webSocketHandler((WebSocketChannel webSocket, _) {
      logger.info('new listener for $event');
      webSocket.sink.done.then(
        (value) => loadedEvents[event]?.listeners.remove(webSocket),
      );
      loadedEvents[event]?.listeners.add(webSocket);

      webSocket.stream.listen((message) {
        if (message == "PING") {
          webSocket.sink.add("PONG");
          return;
        }
        if (message == "PONG") {
          // Ignore pong
          return;
        }

        try {
          final decoded =
              json.decode(message as String) as Map<String, dynamic>;
          logger.fine("got socket message");

          switch (decoded['type'] as String) {
            case SocketMessageType.ping:
              webSocket.sink.add(jsonEncode({"type": "pong", "value": "pong"}));
          }
        } catch (e, s) {
          logger.severe("failed to handle socket message", e, s);
        }
      });
    }, pingInterval: const Duration(hours: 8));

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

  app.delete("/events/<eventID>", (Request request, String eventID) {
    eventID = Uri.decodeComponent(eventID);
    // Since this edits db files, it could conflict with other writes
    return dbWriteLock.synchronized(() async {
      if ((request.headers['upload_password'] ?? '') !=
          env.getOrElse("upload_password", () => '')) {
        return Response.unauthorized("upload_password is invalid");
      }

      logger.info("Attempting file delete for event name $eventID");
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
        'Content-Type': ContentType(
          'application',
          'json',
          charset: 'utf-8',
        ).toString(),
      },
    );
  });

  app.get("/events/<eventID>", (Request request, String eventID) async {
    eventID = Uri.decodeComponent(eventID);
    final event = await _loadFromDisk(eventID);
    if (event == null) {
      return Response.badRequest(body: 'event not found');
    }

    return Response.ok(
      cbor.encode(event.toCbor()),
      headers: {'Content-Type': ContentType.binary.toString()},
    );
  });

  /// Gets an ordered list of all message hashes in the database
  /// Using json is fine here because gzip makes the file size about the same as binary encoding
  /// This also makes it easier to debug
  app.get("/events/<eventID>/index", (Request request, String eventID) async {
    eventID = Uri.decodeComponent(eventID);
    final event = await _loadFromDisk(eventID);
    if (event == null) {
      return Response.badRequest(body: 'event not found');
    }

    final messageHashes = <String>[];
    for (final action in event.actions) {
      messageHashes.add(base64UrlEncode(await action.hash));
    }
    return Response.ok(
      json.encode(messageHashes),
      headers: {'Content-Type': ContentType.json.toString()},
    );
  });

  /// Gets a specific message by its base64 hash
  app.get("/events/<eventID>/messages/<messageID>", (
    Request request,
    String eventID,
    String messageID,
  ) async {
    eventID = Uri.decodeComponent(eventID);
    final event = await _loadFromDisk(eventID);
    if (event == null) {
      return Response.badRequest(body: 'event not found');
    }

    for (final action in event.actions) {
      if (base64UrlEncode(await action.hash) == messageID) {
        return Response.ok(
          cbor.encode(action.toCbor()),
          headers: {'Content-Type': ContentType.binary.toString()},
        );
      }
    }
    return Response.notFound(
      'message $messageID not found',
      headers: {'Content-Type': ContentType.json.toString()},
    );
  });

  app.put("/events/<eventID>", (Request request, String eventID) {
    eventID = Uri.decodeComponent(eventID);
    // Require all writes to start with reading the file, only one at a time and do a full disk flush
    return dbWriteLock.synchronized(() async {
      final File? f = loadedEvents[eventID]?.file;
      if (f == null || await f.exists() == false) {
        return Response.notFound("Event not found");
      }
      final event = SnoutDBFile.fromCbor(
        cbor.decode(await f.readAsBytes()) as CborMap,
      );

      // TODO verify this works lol
      final List<int> content = await request.read().fold(
        <int>[],
        (a, b) => [...a, ...b],
      );

      print(content);
      try {
        final SignedChainMessage message = SignedChainMessage.fromCbor(
          cbor.decode(content) as CborMap,
        );

        final dbWithNewMessage = SnoutChain.fromFile(event);
        // Verify change is valid
        await dbWithNewMessage.verifyApplyAction(message);

        logger.fine('added message: ${message.toCbor()}');

        //Successful message, send this update to all listeners
        for (final WebSocketChannel listener
            in loadedEvents[eventID]?.listeners ?? []) {
          listener.sink.add(
            json.encode({
              "type": SocketMessageType.newPatchId,
              "message": base64UrlEncode(await message.hash),
            }),
          );
        }

        //Write the new DB to disk
        await f.writeAsBytes(
          cbor.encode(SnoutDBFile(actions: dbWithNewMessage.actions).toCbor()),
          flush: true,
        );

        return Response.ok("");
      } catch (e, s) {
        logger.severe('failed to accept message: $content', e, s);
        return Response.internalServerError(body: e.toString());
      }
    });
  });

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
  //Enable GZIP compression since every byte counts!
  // even though the new binary format is efficient, gzip can still save ~30%
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
