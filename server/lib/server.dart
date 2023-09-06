import 'dart:async';
import 'dart:convert';

import 'package:dotenv/dotenv.dart';
import 'package:rfc_6901/rfc_6901.dart';
import 'package:server/edit_lock.dart';
import 'package:shelf_gzip/shelf_gzip.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'dart:io';

import 'package:snout_db/patch.dart';
import 'package:snout_db/snout_db.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

//TODO implement https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/ETag

final env = DotEnv(includePlatformEnvironment: true)..load();
int serverPort = 6749;
Map<String, EventData> loadedEvents = {};
//To keep things simple we will just have 1 edit lock for all loaded events.
EditLock editLock = EditLock();

var app = Router();

//Stuff that should be done for each event that is loaded.
class EventData {
  EventData(this.file);

  File file;
  List<WebSocketChannel> listeners = [];
}

//Load all events from disk and instantiate an event data class for each one
Future loadEvents() async {
  final dir = Directory('events');
  final List<FileSystemEntity> allEvents = await dir.list().toList();
  for (final event in allEvents) {
    if (event is File) {
      print(event.uri.pathSegments.last);
      loadedEvents[event.uri.pathSegments.last] = EventData(event);
    }
  }
}

void main(List<String> args) async {
  await loadEvents();

  app.get("/listen/<event>", (Request request, String event) {
    var handler = webSocketHandler((WebSocketChannel webSocket) {
      print('new listener for $event');
      webSocket.sink.done
          .then((value) => loadedEvents[event]?.listeners.remove(webSocket));
      loadedEvents[event]?.listeners.add(webSocket);
      // webSocket.stream.listen((message) {
      //   webSocket.sink.add("echo $message");
      // });
    }, pingInterval: Duration(hours: 8));

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

  app.get("/events", (Request request) {
    return Response.ok(json.encode(loadedEvents.keys.toList()));
  });

  app.get("/events/<eventID>", (Request request, String eventID) async {
    File? f = loadedEvents[eventID]?.file;
    if (f == null || await f.exists() == false) {
      return Response.notFound("Event not found");
    }
    final event = SnoutDB.fromJson(json.decode(await f.readAsString()));

    return Response.ok(json.encode(event), headers: {
      'Content-Type':
          ContentType('application', 'json', charset: 'utf-8').toString(),
    });
  });

  app.get("/events/<eventID>/patchDiff",
      (Request request, String eventID) async {
    File? f = loadedEvents[eventID]?.file;
    if (f == null || await f.exists() == false) {
      return Response.notFound("Event not found");
    }
    final event = SnoutDB.fromJson(json.decode(await f.readAsString()));

    final clientHead = request.headers["head"];
    if (clientHead == null) {
      return Response(406, body: "send head");
    }
    int clientHeadInt = int.parse(clientHead);

    if (clientHeadInt < 1) {
      return Response(406, body: 'head cannot be less than 1');
    }

    final range = event.patches.getRange(clientHeadInt, event.patches.length);

    return Response.ok(json.encode(range.toList()), headers: {
      'Content-Type':
          ContentType('application', 'json', charset: 'utf-8').toString(),
    });
  });

  app.get("/events/<eventID>/<subPath|.*>",
      (Request request, String eventID, String subPath) async {
    File? f = loadedEvents[eventID]?.file;
    if (f == null || await f.exists() == false) {
      return Response.notFound("Event not found");
    }
    final event = SnoutDB.fromJson(json.decode(await f.readAsString()));

    try {
      var dbJson = json.decode(json.encode(event));
      final pointer = JsonPointer('/$subPath');
      dbJson = pointer.read(dbJson);
      return Response.ok(json.encode(dbJson), headers: {
        'Content-Type':
            ContentType('application', 'json', charset: 'utf-8').toString(),
      });
    } catch (e) {
      print(e);
      return Response.internalServerError(body: e);
    }
  });

  app.put("/events/<eventID>", (Request request, String eventID) async {
    File? f = loadedEvents[eventID]?.file;
    if (f == null || await f.exists() == false) {
      return Response.notFound("Event not found");
    }
    final event = SnoutDB.fromJson(json.decode(await f.readAsString()));
    try {
      //Uses UTF-8 by default
      String content = await request.readAsString();
      Patch patch = Patch.fromJson(json.decode(content));

      event.addPatch(patch);

      print(json.encode(patch));

      //Successful patch, send this update to all listeners
      for (final WebSocketChannel listener
          in loadedEvents[eventID]?.listeners ?? []) {
        listener.sink.add(json.encode(patch));
      }

      //Write the new DB to disk
      await f.writeAsString(json.encode(event));

      return Response.ok("");
    } catch (e) {
      print(e);
      return Response.internalServerError(body: e);
    }
  });

  var handler = const Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(handleCORS())
      .addMiddleware(gzipMiddleware)
      .addHandler(app);

  HttpServer server =
      await shelf_io.serve(handler, InternetAddress.anyIPv4, serverPort);
  //Enable GZIP compression since every byte counts and the performance hit is
  //negligable for the 30%+ compression depending on how much of the data is image
  server.autoCompress = true;
  //TODO i think this will work if chunked transfer encoding is set..

  print('Server started: ${server.address} port ${server.port}');
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
