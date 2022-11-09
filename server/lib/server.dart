import 'dart:convert';

import 'package:rfc_6901/rfc_6901.dart';
import 'package:snout_db/patch.dart';
import 'package:snout_db/snout_db.dart';
import 'package:server/edit_lock.dart';
import 'dart:io';

late SnoutDB db;
late Season season;

//TODO use environment to define port number
int serverPort = 6749;

EditLock editLock = EditLock();

List<WebSocket> patchListeners = [];

void main(List<String> args) async {
  HttpServer server =
      await HttpServer.bind(InternetAddress.anyIPv4, serverPort);
  print('Server started: ${server.address} port ${server.port}');

  String databaseText = await File('database.json').readAsString();
  db = SnoutDB.fromJson(jsonDecode(databaseText));
  String seasonData = await File('season.json').readAsString();
  season = Season.fromJson(jsonDecode(seasonData));

  //Listen for requests
  server.listen((HttpRequest request) async {
    print(request.uri);

    //Cors stuff
    request.response.headers.add('Access-Control-Allow-Origin', '*');
    request.response.headers.add('Access-Control-Allow-Headers', '*');
    request.response.headers.add('Access-Control-Allow-Methods', '*');
    request.response.headers.add('Access-Control-Request-Method', '*');
    if (request.method == "OPTIONS") {
      request.response.close();
      return;
    }

    //Handle patch listener requests
    if (request.uri.toString() == "/patchlistener") {
      WebSocketTransformer.upgrade(request).then((WebSocket websocket) {
        patchListeners.add(websocket);
      });
      return;
    }

    if (request.uri.toString() == "/edit_lock") {
      return handleEditLockRequest(request);
    }

    if (request.uri.toString() == "/season") {
      request.response.headers.contentType =
          new ContentType("application", "json");
      request.response.write(jsonEncode(season));
      request.response.close();
      return;
    }

    if (request.uri.toString() == "/data" && request.method == "PUT") {
      //Patch the database
      String content = await utf8.decodeStream(request);
      try {
        Patch patch = Patch.fromJson(jsonDecode(content));
        db = patch.patch(db);
        request.response.close();

        //Clean up closed connections
        patchListeners.removeWhere((element) => element.closeCode != null);

        //Successful patch, send this update to all listeners
        for (var listener in patchListeners) {
          listener.add(jsonEncode(patch));
        }

        return;
      } catch (e) {
        print(e);
        request.response.statusCode = 500;
        request.response.write(e);
        request.response.close();
        return;
      }
    }

    if (request.uri.toString() == "/data") {
      request.response.headers.contentType =
          new ContentType("application", "json");
      request.response.write(jsonEncode(db));
      request.response.close();
      return;
    }

    if (request.uri.toString().startsWith("/q/")) {
      request.response.headers.contentType =
          new ContentType("application", "json");

      var dbJson = jsonDecode(jsonEncode(db));
      final pointer =
          JsonPointer(request.uri.toString().replaceRange(0, 2, ''));
      print(request.uri.toString().replaceRange(0, 2, ''));
      dbJson = pointer.read(dbJson);

      request.response.write(jsonEncode(dbJson));
      request.response.close();
      return;
    }

    if (request.uri.toString() == "/field_map.png") {
      File image = new File("field_map.png");
      var data = await image.readAsBytes();
      request.response.headers.set('Content-Type', 'image/png');
      request.response.headers.set('Content-Length', data.length);
      request.response.headers.set('Cache-Control', 'max-age=604800');
      request.response.add(data);
      request.response.close();
      return;
    }

    request.response.statusCode = 404;
    request.response.write("Not Found");
    request.response.close();
  });
}

void handleEditLockRequest(HttpRequest request) {
  final key = request.headers.value("key");
  if (key == null) {
    request.response.write("invalid key");
    request.response.close();
    return;
  }
  if (request.method == "GET") {
    final lock = editLock.get(key);
    if (lock) {
      request.response.write(true);
      request.response.close();
      return;
    }
    request.response.write(false);
    request.response.close();
    return;
  }
  if (request.method == "POST") {
    editLock.set(key);
    request.response.close();
    return;
  }
  if (request.method == "DELETE") {
    editLock.clear(key);
    request.response.close();
    return;
  }
}
