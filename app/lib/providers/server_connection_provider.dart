import 'dart:async';
import 'dart:convert';

import 'package:app/api.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snout_db/patch.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class ServerConnectionProvider extends ChangeNotifier {

  String serverURL = "http://localhost:6749";

  bool connected = true;

  //Used in the UI to see failed and successful patches
  List<String> failedPatches = <String>[];

  //This timer is set and will trigger a re-connect if a ping is not recieved
  //It will also
  //within a certain amount of time.
  Timer? _connectionTimer;
  WebSocketChannel? _channel;



  ServerConnectionProvider () {
    // reconnect();

    //Initialize the patches array to be used in the UI.
    () async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      failedPatches = prefs.getStringList("failed_patches") ?? [];

      //Load data and initialize the app
      serverURL = prefs.getString("server") ?? "http://localhost:6749";

      // try {
      //   //Load season config from server
      //   final data = await apiClient.get(Uri.parse(serverURL));
      //   db = FRCEvent.fromJson(json.decode(data.body));
      //   prefs.setString(serverURL, data.body);
      // } catch (e) {
      //   try {
      //     //Load from cache
      //     String? dbCache = prefs.getString(serverURL);
      //     db = FRCEvent.fromJson(json.decode(dbCache!));
      //   } catch (e) {
      //     //Really bad we have no cache or server connection
      //     return;
      //   }
      // }
    }();
  }

  //Writes a patch to local disk and submits it to the server.
  Future addPatch(Patch patch) async {

    SharedPreferences prefs = await SharedPreferences.getInstance();
    try {
      final res =
          await apiClient.put(Uri.parse(serverURL), body: json.encode(patch));
      if (res.statusCode == 200) {
        //Remove it from the failed patches if it exists there
        if (failedPatches.contains(json.encode(patch))) {
          failedPatches.remove(json.encode(patch));
          prefs.setStringList("failed_patches", failedPatches);
        }
        return true;
      } else {
        failedPatches = prefs.getStringList("failed_patches") ?? [];
        if (failedPatches.contains(json.encode(patch)) == false) {
          //Do not add the same patch multiple times into the failed patches!
          failedPatches.add(json.encode(patch));
        }
        prefs.setStringList("failed_patches", failedPatches);
      }
    } catch (e) {
      failedPatches = prefs.getStringList("failed_patches") ?? [];
      if (failedPatches.contains(json.encode(patch)) == false) {
        //Do not add the same patch multiple times into the failed patches!
        failedPatches.add(json.encode(patch));
      }
      prefs.setStringList("failed_patches", failedPatches);
    }
    notifyListeners();
  }

  Future setServer(String newServer) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString("server", newServer);
    serverURL = newServer;

    notifyListeners();
  }

//Attempts to sync with the server
  Future tryOriginSync() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      //Load season config from server
      final data = await apiClient.get(Uri.parse(serverURL));
      //TODO apply patch to local state
      // db = FRCEvent.fromJson(json.decode(data.body));
      prefs.setString(serverURL, data.body);
      notifyListeners();
    } catch (e) {
      Logger.root.warning("origin sync error", e);
    }
  }

  // void resetConnectionTimer() {
  //   _connectionTimer?.cancel();
  //   _connectionTimer = Timer(const Duration(seconds: 61), () {
  //     //No message has been recieved in 60 seconds, close down the connection.
  //     _channel?.sink.close();
  //     connected = false;
  //   });
  // }

  // void reconnect() async {
  //   //Do not close the stream if it already exists idk how that behaves
  //   //it might reuslt in the onDone being called unexpetedly.
  //   Uri serverUri = Uri.parse(serverURL);
  //   _channel = WebSocketChannel.connect(Uri.parse(
  //       '${serverURL.startsWith("https") ? "wss" : "ws"}://${serverUri.host}:${serverUri.port}/listen/${serverUri.pathSegments[1]}'));

  //   _channel!.ready.then((_) {
  //     if (connected == false) {
  //       //Only do an origin sync if we were previouosly not connected
  //       //Since the db is syncronized before creating this object
  //       //we can assume that connection exists for the first reconnect
  //       //thus connected = true by default
  //       tryOriginSync();
  //     }
  //     connected = true;
  //     notifyListeners();
  //     resetConnectionTimer();
  //   });

  //   _channel!.stream.listen((event) async {
  //     resetConnectionTimer();
  //     //REALLY JANK PING PONG SYSTEM THIS SHOULD BE FIXED!!!!
  //     if (event == "PING") {
  //       _channel!.sink.add("PONG");
  //       return;
  //     }

  //     //TODO apply patch to local state
  //     // db = Patch.fromJson(json.decode(event)).patch(db);
  //     // final prefs = await SharedPreferences.getInstance();
  //     // //Save the database to disk
  //     // prefs.setString("db", json.encode(db));
  //     notifyListeners();
  //   }, onDone: () {
  //     connected = false;
  //     notifyListeners();
  //     //Re-attempt a connection after some time
  //     Timer(const Duration(seconds: 4), () {
  //       if (connected == false) {
  //         reconnect();
  //       }
  //     });
  //   }, onError: (e) {
  //     //Dont try and reconnect on an error
  //     Logger.root.warning("DB Listener Error; not attempting to reconnect", e);
  //     notifyListeners();
  //   });
  // }

  //Clears all of the failed patches.
  Future clearFailedPatches() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    failedPatches.clear(); //For UI update
    prefs.setStringList("failed_patches", []);
    notifyListeners();
  }
}