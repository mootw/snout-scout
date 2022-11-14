import 'dart:convert';

import 'package:rfc_6901/rfc_6901.dart';
import 'package:snout_db/event/frcevent.dart';
import 'package:server/edit_lock.dart';
import 'dart:io';

import 'package:snout_db/patch.dart';

//TODO use environment to define port number
int serverPort = 6749;

EditLock editLock = EditLock();

Map<String, List<WebSocket>> patchListeners = {};

void main(List<String> args) async {
  HttpServer server =
      await HttpServer.bind(InternetAddress.anyIPv4, serverPort);
  print('Server started: ${server.address} port ${server.port}');

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

    //Handle listener requests
    if (request.uri.pathSegments[0] == 'listen' &&
        request.uri.pathSegments.length > 1) {
      WebSocketTransformer.upgrade(request).then((WebSocket websocket) {
        final event = request.uri.pathSegments[1];
        patchListeners[event] ??= [];
        patchListeners[event]!.add(websocket);
        print(patchListeners[event]);
      });
      return;
    }

    if (request.uri.toString() == "/edit_lock") {
      return handleEditLockRequest(request);
    }

    // event/some_name
    if (request.uri.pathSegments[0] == 'event' &&
        request.uri.pathSegments.length > 1) {
      final eventID = request.uri.pathSegments[1];
      File f = File('$eventID.json');
      if (await f.exists() == false) {
        request.response.statusCode = 404;
        request.response.write('Event not found');
        request.response.close();
        return;
      }
      var event = FRCEvent.fromJson(jsonDecode(await f.readAsString()));

      if (request.method == 'GET') {
        if (request.uri.pathSegments.length > 2 &&
            request.uri.pathSegments[2] != "") {
          //query was for a specific sub-item. Path segments with a trailing zero need to be filtered
          //event/2022mnmi2 is not the same as event/2022mnmi2/
          try {
            var dbJson = jsonDecode(jsonEncode(event));
            final pointer = JsonPointer(
                '/${request.uri.pathSegments.sublist(2).join("/")}');
            dbJson = pointer.read(dbJson);
            request.response.headers.contentType =
                new ContentType('application', 'json');
            request.response.write(jsonEncode(dbJson));
            request.response.close();
            return;
          } catch (e) {
            print(e);
            request.response.statusCode = 500;
            request.response.write(e);
            request.response.close();
            return;
          }
        }

        request.response.headers.contentType =
            new ContentType('application', 'json');
        request.response.write(jsonEncode(event));
        request.response.close();
        return;
      }

      if (request.method == "PUT") {
        try {
          String content = await utf8.decodeStream(request);
          Patch patch = Patch.fromJson(jsonDecode(content));

          event = patch.patch(event);
          //Write the new DB to disk
          await f.writeAsString(jsonEncode(event));
          request.response.close();

          print(jsonEncode(patch));

          //Successful patch, send this update to all listeners
          for (final listener in patchListeners[eventID] ?? []) {
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
