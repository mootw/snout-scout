import 'dart:async';
import 'dart:convert';

import 'package:dotenv/dotenv.dart';
import 'package:rfc_6901/rfc_6901.dart';
import 'package:snout_db/event/frcevent.dart';
import 'package:server/edit_lock.dart';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:snout_db/event/match.dart';

import 'package:snout_db/patch.dart';

final env = DotEnv(includePlatformEnvironment: true)..load();

int serverPort = 6749;

Map<String, EventData> loadedEvents = {};

//To keep things simple we will just have 1 edit lock for all loaded events.
EditLock editLock = EditLock();

//Stuff that should be done for each event that is loaded.
class EventData {
  EventData(this.file);

  File file;
  List<WebSocket> listeners = [];
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
  if (env.isDefined('X-TBA-Auth-Key') == false) {
    print(
        "NO X-TBA-Auth-Key detected. Create a .env or set env to X-TBA-Auth-Key=key");
  }

  //REALLY JANK PING PONG SYSTEM
  //I SHOULD BE USING listener.pingInterval BUT THE CLIENT ISNT RESPONING
  //TO THE PING MESSAGES FOR SOME REASON (RESULTING IN THE CONNECTION CLOSING AFTER 1.5 DURATIONS)
  //BY THE SERVER. IF I LEAVE PING DURATION NULL THE CONNECTION CLOSES 1006 AFTER 60 seconds
  //I think this is a client side or proxy side thing.
  Timer.periodic(Duration(seconds: 30), (timer) {
    for(final event in loadedEvents.values) {
      for (final listener in event.listeners) {
        listener.add("PING");
      }
    }
  });
  

  await loadEvents();

  HttpServer server =
      await HttpServer.bind(InternetAddress.anyIPv4, serverPort);
  print('Server started: ${server.address} port ${server.port}');

  //Listen for requests
  server.listen((HttpRequest request) async {
    print(request.uri);

    //CORS stuff
    request.response.headers.add('Access-Control-Allow-Origin', '*');
    request.response.headers.add('Access-Control-Allow-Headers', '*');
    request.response.headers.add('Access-Control-Allow-Methods', '*');
    request.response.headers.add('Access-Control-Request-Method', '*');
    if (request.method == "OPTIONS") {
      request.response.close();
      return;
    }

    //Handle listener requests
    if (request.uri.pathSegments.length > 1 &&
        request.uri.pathSegments[0] == 'listen') {
      WebSocketTransformer.upgrade(request).then((WebSocket websocket) {
        final event = request.uri.pathSegments[1];
        //Set the ping interval to keep the connection alive for many browser's and proxy's default behavior.
        //For some reason this doesnt work client side so the server will just close the connection after 16 hours
        //the client will reconnect though so it "works". If pingInterval is fixed on the client side this can be reduced
        //and used as the primary connection indicator. Maybe 30 seconds
        websocket.pingInterval = Duration(hours: 12);
        //Remove the websocket from the listeners when it is closed for any reason.
        websocket.done.then((value) => loadedEvents[event]?.listeners.remove(websocket));
        loadedEvents[event]?.listeners.add(websocket);
      });
      return;
    }

    //Load schedule stuff.
    if (request.uri.pathSegments.length > 1 &&
        request.uri.pathSegments[0] == 'load_schedule') {

      final eventID = request.uri.pathSegments[1];

      File? f = loadedEvents[eventID]?.file;
      if (f == null || await f.exists() == false) {
        print("event not found");
        request.response.statusCode = 404;
        request.response.write('Event not found');
        request.response.close();
        return;
      }
      //Attempt to laod the schedule from the API
      try {
        final eventData = FRCEvent.fromJson(jsonDecode(await f.readAsString()));

        await loadScheduleFromTBA(eventData, eventID);
        
        request.response.write("Done adding matches");
        request.response.close();
        return;
      } catch (e, s) {
        print(e);
        print(s);
        request.response.statusCode = 500;
        request.response.write(e);
        request.response.close();
      }
    }

    if (request.uri.toString() == "/edit_lock") {
      return handleEditLockRequest(request);
    }

    if (request.uri.toString() == "/events") {
      request.response.write(loadedEvents.keys.toList());
      request.response.close();
      return;
    }

    // event/some_name
    if (request.uri.pathSegments.length > 1 &&
        request.uri.pathSegments[0] == 'events') {
      final eventID = request.uri.pathSegments[1];
      File? f = loadedEvents[eventID]?.file;
      if (f == null || await f.exists() == false) {
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
          //events/2022mnmi2 is not the same as event/2022mnmi2/
          try {
            var dbJson = jsonDecode(jsonEncode(event));
            final pointer = JsonPointer(
                '/${request.uri.pathSegments.sublist(2).join("/")}');
            dbJson = pointer.read(dbJson);
            request.response.headers.contentType =
            new ContentType('application', 'json', charset: 'utf-8');
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
            new ContentType('application', 'json', charset: 'utf-8');
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
          for (final listener in loadedEvents[eventID]?.listeners ?? []) {
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

//https://www.thebluealliance.com/apidocs/v3
Future loadScheduleFromTBA(FRCEvent eventData, String eventID) async {

  if(eventData.config.tbaEventId == null) {
    throw Exception("TBA event ID cannot be null in the config!");
  }
  
  //Get playoff level matches
  final apiData = await http.get(
      Uri.parse(
          "https://www.thebluealliance.com/api/v3/event/${eventData.config.tbaEventId}/matches"),
      headers: {
        'X-TBA-Auth-Key': env['X-TBA-Auth-Key']!,
      });
  

  //Alright I THINK the timezone for the iso string is the one local to the event, but this would be chaotic
  //(and not to the ISO8601 standard since it should show timezone offset meaning the actual time is WRONG)
  //Basically just place your server in the same timezone as the event and hope for the best lmao

  final matches = jsonDecode(apiData.body);

  for (final match in matches) {
    String key = match['key'];
    DateTime startTime = DateTime.fromMillisecondsSinceEpoch(match['time'] * 1000, isUtc: true);

    //"red": {
    //   "dq_team_keys": [],
    //   "score": 86,
    //   "surrogate_team_keys": [],
    //   "team_keys": [
    //     "frc2883",
    //     "frc2239",
    //     "frc2129"
    //   ]
    // }
    List<int> red = [
      for(String team in match['alliances']['red']['team_keys'])
        int.parse(team.substring(3)),
    ];
    List<int> blue = [
      for(String team in match['alliances']['blue']['team_keys'])
        int.parse(team.substring(3)),
    ];

    int matchNumber = match['match_number'];
    int setNumber = match['set_number'];
    String compLevel = match['comp_level'];
    //Generate a human readable description for each match
    String description;
    //qm, ef, qf, sf, f
    if(compLevel == "qm") {
      description = "Quals $matchNumber";
    } else if (compLevel == "ef") {
      description = "Eighths $matchNumber Match $setNumber";
    }else if (compLevel == "qf") {
      description = "Quarters $matchNumber Match $setNumber";
    } else if (compLevel == "sf") {
      description = "Semis $matchNumber Match $setNumber";
    } else if (compLevel == "f") {
      description = "Finals $matchNumber";
    } else {
      description = "Unknown $matchNumber";
    }

    //ONLY modify matches that do not exist yet to prevent damage
    if (eventData.matches.keys.toList().contains(key) == false) {
      print("match ${key} does not exist; adding...");
      FRCMatch newMatch = FRCMatch(
          description: description,
          number: matchNumber,
          scheduledTime: startTime,
          blue: blue,
          red: red,
          results: null,
          robot: {});

      Patch patch = Patch(
          time: DateTime.now(),
          path: [
            'matches',
            key,
          ],
          data: jsonEncode(newMatch));

      print(jsonEncode(patch));

      await http.put(
          Uri.parse("http://localhost:$serverPort/events/$eventID"),
          body: jsonEncode(patch));
    }
  }
}
