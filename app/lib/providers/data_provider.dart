import 'dart:async';
import 'dart:convert';

import 'package:app/api.dart';
import 'package:app/screens/configure_source.dart';
import 'package:app/services/data_service.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snout_db/event/frcevent.dart';
import 'package:snout_db/patch.dart';
import 'package:snout_db/snout_db.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// determines how the app should load data and apply changes
enum DataSource {
  memory(value: 'memory'),
  localDisk(value: 'localDisk'),
  remoteServer(value: 'remoteServer');

  const DataSource({
    required this.value,
  });

  final String value;
  String toJson() => value;

  factory DataSource.fromJson(String data) {
    for (final item in DataSource.values) {
      if (item.value == data) {
        return item;
      }
    }
    throw Exception("$data is not a valid data source");
  }
}

class DataProvider extends ChangeNotifier {
  //Initialize the database as empty
  //this value should get quickly overwritten
  //i just dont like this being nullable is all.
  SnoutDB database = SnoutDB(patches: [
    Patch(
      identity: 'root',
      path: Patch.buildPath(['']),
      time: DateTime.now(),
      value: emptyNewEvent.toJson(),
    )
  ]);

  DataSource dataSource = DataSource.memory;

  FRCEvent get event => database.event;

  DataProvider() {
    () async {
      final prefs = await SharedPreferences.getInstance();

      dataSource = DataSource.fromJson(
          prefs.getString('dataSource') ?? DataSource.memory.toJson());

      _loadSelectedDataSource();

      notifyListeners();
    }();

    //Initialize the patches array to be used in the UI.
    () async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      failedPatches = prefs.getStringList("failed_patches") ?? [];

      //Load data and initialize the app
      serverURL = prefs.getString("server") ?? "http://localhost:6749";
      selectedEvent = prefs.getString("selectedServerFile");
    }();
  }

  /// Changing the data source requires a few things
  /// depending on the source
  Future setDataSource(DataSource newSource) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString("dataSource", newSource.toJson());
    dataSource = newSource;
    notifyListeners();
    _loadSelectedDataSource();
  }

  Future _loadSelectedDataSource() async {
    switch (dataSource) {
      case DataSource.memory:
        //DO NOTHING
        break;
      case DataSource.localDisk:
        await loadLocalDBData();
        break;
      case DataSource.remoteServer:
        await getDatabaseFromServer();
        break;
    }
  }

  //Writes a patch to local disk and submits it to the server.
  Future submitPatch(Patch patch) async {
    switch (dataSource) {
      case DataSource.memory:
        database.addPatch(patch);
        break;
      case DataSource.localDisk:
        database.addPatch(patch);
        await writeLocalDiskDatabase(database);
        break;
      case DataSource.remoteServer:
        database.addPatch(patch);
        await postPatchToServer(patch);
        //importantly we DO NOT save this 
        //to our local latest state, just
        //like with incoming patches due to
        //that potentially ruining the state
        //of the local database....
        break;
    }

    notifyListeners();
  }

  // LOCAL DB STUFF
  ///
  //

  // saves the data into storage
  Future writeLocalDiskDatabase(SnoutDB db) async {
    await storeText("local_db", json.encode(db.toJson()));
    notifyListeners();
  }

  Future loadLocalDBData() async {
    final data = await readText("local_db");
    if (data == null) {
      Logger.root.severe("local data is null oops");
      return;
    }
    database = SnoutDB.fromJson(json.decode(data));
    notifyListeners();
  }

  /// I AM TREATING THIS AS A THE SERVER HANDLING "PART"
  /// I REALLY WANTED THIS TO BE ANOTHER FILE BUT UNFORTUNATELY
  /// EVERYTHING I DID MADE IT SLIGHTLY ANNOTYING LIKE I WANTED
  /// TO MAKE THE STATE WORK BUT THERE ARE UI ACCESSED DATAS IN
  /// THIS FILE SO IT NEEDS TO BE A NOTIFIER PROVIDER WHICH I KNOW
  /// IS BAD PRACTICE TO HAVE YOUR UI STATE STORED IN A 'SERVICE'
  /// FILE BUT LIKE IT MAKES THE CODE SO MUCH CLEANER AND I NEED TO
  /// BE ABLE TO CALL FUNCTIONS FROM THIS FILE FROM THE DATA PROVIDER
  /// FILE AND VICE VERSA SO IN THE END I KINDA JUST DECIDED TO THROW
  /// IT ALL INTO ONE FILE AND NOW HERE WE ARE WITH ME RANTING ABOUT
  /// HOW IT FOILED MY PLANS. I CATUALLY TRIED TO PUT THIS PART AS
  /// AN OBJECT INTO THE DATA PROVIDER CLASS AND THEN HAVE THE DATA
  /// PROVIDER CLASS INJECT ITSELF INTO THIS SO THIS CLASS COULD
  /// 'CALL UP' THE NOTIFIER BUT THE DART ANALYSIS ENGINE IS TOO SMART
  /// FOR ME :SOBBING:

  String serverURL = "http://localhost:6749";

  String? selectedEvent;

  String get selectedEventStorageKey =>
      base64Encode(utf8.encode(getEventPath.toString()));

  Uri get serverURI => Uri.parse(serverURL);

  //Root path for the selected event
  Uri get getEventPath => serverURI.resolve("/events/$selectedEvent");

  bool connected = true;

  //Used in the UI to see failed and successful patches
  List<String> failedPatches = <String>[];

  //This timer is set and will trigger a re-connect if a ping is not recieved
  //It will also
  //within a certain amount of time.
  Timer? _connectionTimer;
  WebSocketChannel? _channel;

  Future<List<String>> getEventList() async {
    final url = serverURI.resolve("/events");
    final result = await apiClient.get(url);
    return List<String>.from(json.decode(result.body));
  }

  //this will load the entire database if it has
  //not been loaded yet, OR it will load only
  //the changes that have been made since it's
  //last download.
  Future getDatabaseFromServer() async {
    final storageKey = selectedEventStorageKey;
    final diskData = await readText(storageKey);

    Uri path = Uri.parse('${getEventPath.toString()}/patches');

    if (diskData == null) {
      print("DISK IS NULL $path");
      //Load the changest only, since it is more bandwidth efficient
      //and the database is ONLY based on patches.
      final newData = await apiClient.get(path);

      //TODO this is hardcoded
      final decodedDatabase =
          SnoutDB.fromJson({"patches": json.decode(newData.body)});
      database = decodedDatabase;
      await storeText(storageKey, json.encode(decodedDatabase));
      notifyListeners();
      return;
    }

    final lastDiskDatabase =
          SnoutDB.fromJson(json.decode(diskData));

    Uri diffPath = Uri.parse('${getEventPath.toString()}/patchDiff');
    
    print("diff path $diffPath");

    final diffResult = await apiClient.get(diffPath, headers: {
      "head": lastDiskDatabase.patches.length.toString(),
    });

    print(diffResult.body);
    
    List<Patch> diffPatches = (json.decode(diffResult.body) as List<dynamic>)
          .map((e) => Patch.fromJson(e as Map))
          .toList();

          print(diffPatches.length);

    database = SnoutDB(patches: [...lastDiskDatabase.patches, ...diffPatches]);
    await storeText(storageKey, json.encode(database));


    notifyListeners();
  }


  //Writes a patch to local disk and submits it to the server.
  Future postPatchToServer(Patch patch) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    try {
      final res =
          await apiClient.put(getEventPath, body: json.encode(patch));
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
  }

  Future setServer(String newServer) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString("server", newServer);
    serverURL = newServer;
    setSelectedEvent(null);

    notifyListeners();
  }

  Future setSelectedEvent(String? newFile) async {
    final prefs = await SharedPreferences.getInstance();
    await deleteText(selectedEventStorageKey);
    if (newFile == null) {
      prefs.remove("selectedServerFile");
    } else {
      prefs.setString("selectedServerFile", newFile);
    }
    selectedEvent = newFile;
    await getDatabaseFromServer(); //Load in the new event data!
    notifyListeners();
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
