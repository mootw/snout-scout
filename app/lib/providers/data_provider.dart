import 'dart:async';
import 'dart:convert';

import 'package:app/api.dart';
import 'package:app/providers/identity_provider.dart';
import 'package:app/providers/loading_status_service.dart';
import 'package:app/screens/configure_source.dart';
import 'package:app/services/data_service.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import 'package:server/socket_messages.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snout_db/db.dart';
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

      //Initialize the patches array to be used in the UI.
      failedPatches = prefs.getStringList("failed_patches") ?? [];

      //Load data and initialize the app
      serverURL = prefs.getString("server") ?? "http://localhost:6749";
      selectedEvent = prefs.getString("selectedServerFile");

      try {
        await _loadSelectedDataSource();
      } catch (e, s) {
        Logger.root.severe("Failed to load data", e, s);
      }

      if (dataSource == DataSource.remoteServer) {
        _initializeLiveServerPatches();
      }

      notifyListeners();
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

  Future _loadSelectedDataSource() {
    final future = () async {
      switch (dataSource) {
        case DataSource.memory:
          //DO NOTHING
          break;
        case DataSource.localDisk:
          await _loadLocalDBData();
          break;
        case DataSource.remoteServer:
          await _getDatabaseFromServer();
          break;
      }
    }();
    loadingService.addFuture(future);
    return future;
  }

  String? oldStatus;

  /// Used to update the server with this scouts status (what they are doing right now) in text form
  void updateStatus(BuildContext context, String newStatus) {
    if (ModalRoute.of(context)?.isCurrent == false) {
      return;
    }
    final identity = context.read<IdentityProvider>().identity;

    if (_channel != null && newStatus != oldStatus) {
      //channel is still open
      _channel?.sink.add(json.encode({
        "type": SocketMessageType.scoutStatusUpdate,
        "identity": identity,
        "value": newStatus,
      }));
      oldStatus = newStatus;
    }
  }

  //Writes a patch to local disk and submits it to the server.
  Future submitPatch(Patch patch) {
    final future = () async {
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
          await _postPatchToServer(patch);
          //importantly we DO NOT save this
          //to our local latest state, just
          //like with incoming patches due to
          //that potentially ruining the state
          //of the local database....
          break;
      }
      notifyListeners();
    }();
    loadingService.addFuture(future);
    return future;
  }

  /// LOCAL DB STUFF
  ///

  /// saves the data into storage
  Future writeLocalDiskDatabase(SnoutDB db) async {
    await storeText('local_patches',
        json.encode(db.patches.map((e) => e.toJson()).toList()));
    notifyListeners();
  }

  Future _loadLocalDBData() async {
    final data = await readText('local_patches');
    if (data == null) {
      Logger.root.severe("local data is null oops");
      return;
    }
    //Decode as list of patches
    final patches = List.from(json.decode(data) as List)
        .map((x) => Patch.fromJson(x))
        .toList();
    database = SnoutDB(patches: patches);
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

  //Used in the UI to see failed and successful patches
  List<String> failedPatches = <String>[];

  bool connected = true;

  WebSocketChannel? _channel;

  //
  List<({String identity, String status, DateTime time})> scoutStatus = [];

  Future<List<String>> getEventList() async {
    final url = serverURI.resolve("/events");
    final result = await apiClient.get(url);
    return List<String>.from(json.decode(result.body));
  }

  //this will load the entire database if it has
  //not been loaded yet, OR it will load only
  //the changes that have been made since it's
  //last download.
  Future _getDatabaseFromServer() async {
    final storageKey = selectedEventStorageKey;
    final diskData = await readText(storageKey);

    Uri path = Uri.parse('${getEventPath.toString()}/patches');

    if (diskData == null) {
      //Load the changest only, since it is more bandwidth efficient
      //and the database is ONLY based on patches.
      final newData = await apiClient.get(path);

      final List<Patch> patches = (json.decode(newData.body) as List)
          .map((e) => Patch.fromJson(e as Map))
          .toList();
      final decodedDatabase = SnoutDB(patches: patches);
      database = decodedDatabase;
      await storeText(storageKey,
          json.encode(decodedDatabase.patches.map((e) => e.toJson()).toList()));
      notifyListeners();
      return;
    }

    //Decode as list of patches
    final patches = List.from(json.decode(diskData) as List)
        .map((x) => Patch.fromJson(x))
        .toList();
    final diskDatabase = SnoutDB(patches: patches);

    //Assign to local database so even when it fails to load, we still have
    //the latest disk database
    database = diskDatabase;
    Uri diffPath = Uri.parse('${getEventPath.toString()}/patchDiff');
    final diffResult = await apiClient.get(diffPath, headers: {
      "head": diskDatabase.patches.length.toString(),
    });

    List<Patch> diffPatches = (json.decode(diffResult.body) as List<dynamic>)
        .map((e) => Patch.fromJson(e as Map))
        .toList();

    if (diffPatches.isNotEmpty) {
      // update local with new patches ONLY if it is not empty
      // since instantiating a SnoutDB is SLOW
      database = SnoutDB(patches: [...diskDatabase.patches, ...diffPatches]);
      await storeText(storageKey,
          json.encode(database.patches.map((e) => e.toJson()).toList()));
    }

    notifyListeners();
  }

  //Writes a patch to local disk and submits it to the server.
  Future _postPatchToServer(Patch patch) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    try {
      final res = await apiClient.put(getEventPath, body: json.encode(patch));
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
    final oldEvent = selectedEvent;
    final prefs = await SharedPreferences.getInstance();
    await deleteText(selectedEventStorageKey);
    if (newFile == null) {
      prefs.remove("selectedServerFile");
    }
    if (newFile != null) {
      //Load in the new event data only if the event is not null
      try {
        selectedEvent = newFile;
        await _getDatabaseFromServer();
        //Save the selectedServerFile AFTER successfully loading it...
        prefs.setString("selectedServerFile", newFile);
      } catch (e, s) {
        Logger.root.severe("failed to select event", e, s);
        //reassign the old event
        selectedEvent = oldEvent;
      }
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

  /// REAL TIME SERVER PATCHES STUFF
  /// -------------------------------
  ///

  //TODO make this elegantly handle when the server url switches during runtime
  //TODO have it correctly shut down an old channel
  void _initializeLiveServerPatches() async {
    //Do not close the stream if it already exists idk how that behaves
    //it might reuslt in the onDone being called unexpetedly.

    // SO the IO implementation supports a ping interval. im like 90% sure there is a bug in the library implementation
    // that makes it not correctly ping or reply to ping messages from the server.
    // I want to avoid having an open dead connection without any frames, because proxies are likely to close it,
    // and users implementing the app will have a hard time debugging the randomly closed connections. so i like the idea
    // of sending garbage frames more regularly (every minute or two), to keep the connection "alive" for proxies
    // right now there is no REASON to send data that frequently. There is a ping option in the IO implementation of the lib
    // but since this is primarily a web app we cant use that.
    _channel = WebSocketChannel.connect(Uri.parse(
        '${serverURL.startsWith("https") ? "wss" : "ws"}://${serverURI.host}:${serverURI.port}/listen/$selectedEvent'));

    _channel!.ready.then((_) {
      if (dataSource != DataSource.remoteServer) {
        return;
      }

      if (connected == false) {
        //Only do an origin sync if we were previouosly not connected
        //Since the db is syncronized before creating this object
        //we can assume that connection exists for the first reconnect
        //thus connected = true by default
        _getDatabaseFromServer();
      }
      connected = true;
      notifyListeners();
    });

    _channel!.stream.listen((event) async {
      if (dataSource != DataSource.remoteServer) {
        return;
      }

      print("new socket message: " + event);

      try {
        final decoded = json.decode(event);

        switch (decoded['type'] as String?) {
          case SocketMessageType.scoutStatus:
            final list = decoded['value'] as List;

            scoutStatus.clear();
            for (final item in list) {
              scoutStatus.add((
                identity: item['identity'],
                status: item['status'],
                time: DateTime.parse(item['time']),
              ));
            }

            break;
          case SocketMessageType.newPatch:
            //apply patch to local state BUT do not save it to
            //disk because it is AMBIGUOUS what the local state is
            final patch = Patch.fromJson(decoded['patch']);

            //Do not add a patch that exists already
            //TODO make the server not send the patch back to the client that sent it, duh
            if (database.patches.any((item) =>
                    json.encode(item.toJson()) ==
                    json.encode(patch.toJson())) ==
                false) {
              database.addPatch(patch);
            }
            break;
          default:
            Logger.root
                .warning("unknown socket message: $event", StackTrace.current);
            break;
        }
      } catch (e, s) {
        Logger.root.severe("socket parse error", e, s);
      }

      // final prefs = await SharedPreferences.getInstance();
      // //Save the database to disk
      // prefs.setString("db", json.encode(db));
      notifyListeners();
    }, onDone: () {
      if (dataSource != DataSource.remoteServer) {
        return;
      }
      connected = false;
      notifyListeners();
      //Re-attempt a connection after some time
      Timer(const Duration(seconds: 2), () {
        if (connected == false) {
          _initializeLiveServerPatches();
        }
      });
    }, onError: (e) {
      //Dont try and reconnect on an error
      Logger.root.warning("DB Listener Error", e);
      notifyListeners();
    });
  }
}
