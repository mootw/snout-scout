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

var env = DotEnv(includePlatformEnvironment: true)..load();

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
  if (env['FRCAPI'] == null) {
    print(
        "NO FRC API key detected. Create a .env or set env to FRCAPI=username:key");
  }

  await loadEvents();

  //Periodic tasks timer
  Timer.periodic(Duration(minutes: 3), (timer) async {
    print("periodic work started");
  });

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
        request.response.statusCode = 404;
        request.response.write('Event not found');
        request.response.close();
        return;
      }
      //Attempt to laod the schedule from the API
      try {
        var eventData = FRCEvent.fromJson(jsonDecode(await f.readAsString()));

        String season = eventID.substring(0, 4); //Get the 4 digit date
        String event = eventID
            .substring(4)
            .toUpperCase(); //FRC uses upper case event stuff
        //Remove json from file if it exists.
        event = event.replaceAll(".JSON", "");

        print(season);
        print(event);

        await loadScheduleFromFRCAPI(eventID, season, event, eventData);
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

    // event/some_name
    if (request.uri.pathSegments.length > 1 &&
        request.uri.pathSegments[0] == 'event') {
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

//Attempt to load the schedule from the official FRC API.
//This code is JANK and designed to be repaired and not cause damage.
//Nowhere near as robust as the main app or API because of it.
//It will make API calls to this server's api to apply the changes
Future loadScheduleFromFRCAPI(
    String eventID, String season, String event, FRCEvent eventData) async {
  final headers = {
    "Authorization": "Basic ${base64Encode(utf8.encode(env["FRCAPI"] ?? ""))}"
  };
  //Get playoff level matches
  final responseQual = await http.get(
      Uri.parse(
          "https://frc-api.firstinspires.org/v3.0/$season/schedule/$event?tournamentLevel=qual"),
      headers: headers);
  //Get playoff level matches
  final responsePlayoff = await http.get(
      Uri.parse(
          "https://frc-api.firstinspires.org/v3.0/$season/schedule/$event?tournamentLevel=playoff"),
      headers: headers);

  //Alright I THINK the timezone for the iso string is the one local to the event, but this would be chaotic
  //(and not to the ISO8601 standard since it should show timezone offset meaning the actual time is WRONG)
  //Basically just place your server in the same timezone as the event and hope for the best lmao

  final matches = [
    ...jsonDecode(responseQual.body)['Schedule'],
    ...jsonDecode(responsePlayoff.body)['Schedule']
  ];

  Map<String, FRCMatch> newMatches = {};

  for (var match in matches) {
    String description = match['description'];
    DateTime startTime = DateTime.parse(match['startTime']);
    int matchNumber = match['matchNumber'];
    List<dynamic> teams = match['teams'];
    TournamentLevel tournamentLevel = TournamentLevel.values.byName(match['tournamentLevel']);

    //Assume they just list teams in order of 1-2-3 red 1-2-3 blue
    List<int> red = [];
    List<int> blue = [];
    for (int i = 0; i < teams.length; i++) {
      if (i < 3) {
        red.add(teams[i]['teamNumber']);
      } else {
        blue.add(teams[i]['teamNumber']);
      }
    }
    print(eventData.matches.keys.toList());
    //ONLY modify matches that do not exist yet to prevent damage
    if (eventData.matches.keys.toList().contains(description) == false) {
      print("match ${description} does not exist adding...");
      newMatches[description] = FRCMatch(
          level: tournamentLevel,
          description: description,
          number: matchNumber,
          scheduledTime: startTime,
          blue: blue,
          red: red,
          results: null,
          robot: {});
    }
  }

  if(newMatches.isEmpty) {
    //Do nothing if we do not need to make a change
    return;
  }

  //Create a patch with the old events and new events.
    final matchPatch = Map.from(eventData.matches)..addAll(newMatches);


    Patch patch = Patch(
      user: "anon",
      time: DateTime.now(),
      path: [
        'matches',
      ],
      data: jsonEncode(matchPatch));

    print(jsonEncode(patch));

    var res = await http.put(Uri.parse("http://localhost:$serverPort/event/$eventID"),
        body: jsonEncode(patch));

  // print(jsonEncode(matches));
}

//Example response from 2022
/*
{
      "description": "Qualification 1",
      "level": null,
      "startTime": "2022-04-08T09:00:00",
      "matchNumber": 1,
      "field": "Primary",
      "tournamentLevel": "Qualification",
      "teams": [
        {
          "teamNumber": 8234,
          "station": "Red1",
          "surrogate": false
        },
        {
          "teamNumber": 4648,
          "station": "Red2",
          "surrogate": false
        },
        {
          "teamNumber": 4277,
          "station": "Red3",
          "surrogate": false
        },
        {
          "teamNumber": 4663,
          "station": "Blue1",
          "surrogate": false
        },
        {
          "teamNumber": 2654,
          "station": "Blue2",
          "surrogate": false
        },
        {
          "teamNumber": 2177,
          "station": "Blue3",
          "surrogate": false
        }
      ]
    },
    */