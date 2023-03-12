
import 'dart:async';
import 'dart:convert';

import 'package:app/api.dart';
import 'package:app/main.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snout_db/event/frcevent.dart';
import 'package:snout_db/patch.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class EventDB extends ChangeNotifier {
  FRCEvent db;

  DateTime? lastOriginSync;
  bool connected = true;

  //This timer is set and will trigger a re-connect if a ping is not recieved
  //It will also
  //within a certain amount of time.
  Timer? connectionTimer;

  WebSocketChannel? channel;

  //Used in the UI to see failed and successful patches
  List<String> successfulPatches = <String>[];
  List<String> failedPatches = <String>[];

  void resetConnectionTimer() {
    connectionTimer?.cancel();
    connectionTimer = Timer(const Duration(seconds: 61), () {
      //No message has been recieved in 60 seconds, close down the connection.
      channel?.sink.close();
      connected = false;
    });
  }

  void reconnect() async {
    //Do not close the stream if it already exists idk how that behaves
    //it might reuslt in the onDone being called unexpetedly.
    Uri serverUri = Uri.parse(serverURL);
    channel = WebSocketChannel.connect(Uri.parse(
        '${serverURL.startsWith("https") ? "wss" : "ws"}://${serverUri.host}:${serverUri.port}/listen/${serverUri.pathSegments[1]}'));

    channel!.ready.then((_) {
      if (connected == false) {
        //Only do an origin sync if we were previouosly not connected
        //Since the db is syncronized before creating this object
        //we can assume that connection exists for the first reconnect
        //thus connected = true by default
        tryOriginSync();
      }
      connected = true;
      notifyListeners();
      resetConnectionTimer();
    });

    channel!.stream.listen((event) async {
      resetConnectionTimer();
      //REALLY JANK PING PONG SYSTEM THIS SHOULD BE FIXED!!!!
      if (event == "PING") {
        channel!.sink.add("PONG");
        return;
      }

      db = Patch.fromJson(jsonDecode(event)).patch(db);
      final prefs = await SharedPreferences.getInstance();
      //Save the database to disk
      prefs.setString("db", jsonEncode(db));
      notifyListeners();
    }, onDone: () {
      connected = false;
      notifyListeners();
      //Re-attempt a connection after some time
      Timer(const Duration(seconds: 4), () {
        if (connected == false) {
          reconnect();
        }
      });
    }, onError: (e) {
      //Dont try and reconnect on an error
      print(e);
      notifyListeners();
    });
  }

  //Attempts to sync with the server
  Future tryOriginSync() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      //Load season config from server
      final data = await apiClient.get(Uri.parse(serverURL));
      db = FRCEvent.fromJson(jsonDecode(data.body));
      prefs.setString(serverURL, data.body);
      prefs.setString("lastoriginsync", DateTime.now().toIso8601String());
      lastOriginSync = DateTime
          .now(); //FOR easy UI update. This is slowly becoming spaghetti
      notifyListeners();
    } catch (e) {
      print(e);
    }
  }

  EventDB(this.db) {
    reconnect();

    //Initialize the patches array to be used in the UI.
    () async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      successfulPatches = prefs.getStringList("successful_patches") ?? [];
      failedPatches = prefs.getStringList("failed_patches") ?? [];
      lastOriginSync =
          DateTime.tryParse(prefs.getString("lastoriginsync") ?? "");
    }();
  }

  //Writes a patch to local disk and submits it to the server.
  Future addPatch(Patch patch) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    try {
      final res =
          await apiClient.put(Uri.parse(serverURL), body: jsonEncode(patch));
      if (res.statusCode == 200) {
        //This was successful
        successfulPatches = prefs.getStringList("successful_patches") ?? [];
        successfulPatches.add(jsonEncode(patch));
        prefs.setStringList("successful_patches", successfulPatches);
        //Remove it from the failed patches if it exists there
        if (failedPatches.contains(jsonEncode(patch))) {
          failedPatches.remove(jsonEncode(patch));
          prefs.setStringList("failed_patches", failedPatches);
        }
        //Apply the patch to the local only if it was successful!
        db = patch.patch(db);
        return true;
      } else {
        failedPatches = prefs.getStringList("failed_patches") ?? [];
        if (failedPatches.contains(jsonEncode(patch)) == false) {
          //Do not add the same patch multiple times into the failed patches!
          failedPatches.add(jsonEncode(patch));
        }
        prefs.setStringList("failed_patches", failedPatches);
      }
    } catch (e) {
      failedPatches = prefs.getStringList("failed_patches") ?? [];
      if (failedPatches.contains(jsonEncode(patch)) == false) {
        //Do not add the same patch multiple times into the failed patches!
        failedPatches.add(jsonEncode(patch));
      }
      prefs.setStringList("failed_patches", failedPatches);
    }
    notifyListeners();
  }

  //Clears all of the failed patches.
  Future clearFailedPatches() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    failedPatches.clear(); //For UI update
    prefs.setStringList("failed_patches", []);
    notifyListeners();
  }

  //Clears all of the successful patches.
  Future clearSuccessfulPatches() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    successfulPatches.clear(); //For UI update
    prefs.setStringList("successful_patches", []);
    notifyListeners();
  }
}