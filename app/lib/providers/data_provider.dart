import 'dart:async';
import 'dart:convert';

import 'package:app/api.dart';
import 'package:app/providers/loading_status_service.dart';
import 'package:app/screens/select_data_source.dart';
import 'package:app/services/data_service.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:server/socket_messages.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snout_db/config/surveyitem.dart';
import 'package:snout_db/db.dart';
import 'package:snout_db/event/frcevent.dart';
import 'package:snout_db/patch.dart';
import 'package:snout_db/snout_db.dart';
import 'package:synchronized/synchronized.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// saves the data into storage
Future writeLocalDiskDatabase(SnoutDB db, Uri path) async {
  final file = fs.file(Uri.decodeFull(path.toString()));
  if (await file.exists() == false) {
    await file.create(recursive: true);
  }
  await file.writeAsBytes(utf8.encode(jsonEncode(db.toJson())));
}

/// To be used within the context of a single data source
class DataProvider extends ChangeNotifier {
  final Uri dataSourceUri;
  final bool kioskClean;

  final loadingLock = Lock();

  // Disgusting way to handle paths but it works so whatever
  bool get isDataSourceUriRemote => dataSourceUri.toString().startsWith('http');

  //Initialize the database as empty
  //this value should get quickly overwritten
  //i just dont like this being nullable is all.
  SnoutDB _database = SnoutDB(
    patches: [
      Patch(
        identity: '',
        path: Patch.buildPath(['']),
        time: DateTime.now(),
        value: emptyNewEvent.toJson(),
      ),
    ],
  );

  set database(SnoutDB newDatabase) {
    _database = newDatabase;
    _santize();
    isInitialLoad = true;
  }

  void _santize() {
    if (kioskClean) {
      // Clean the data if needed
      // final pitScoutingStrings = database.event.config.pitscouting.where((item) => item.type == SurveyItemType.text);
      database.event.config.pitscouting.removeWhere(
        (item) => item.type == SurveyItemType.text,
      );
      database.event.config.matchscouting.survey.removeWhere(
        (item) => item.type == SurveyItemType.text,
      );
    }
  }

  SnoutDB get database {
    return _database;
  }

  bool isInitialLoad = false;

  FRCEvent get event => database.event;

  DataProvider(this.dataSourceUri, [this.kioskClean = false]) {
    () async {
      final prefs = await SharedPreferences.getInstance();

      //Initialize the patches array to be used in the UI.
      failedPatches = prefs.getStringList("failed_patches") ?? [];

      try {
        await _loadSelectedDataSource();
      } catch (e, s) {
        Logger.root.severe("Failed to load data", e, s);
      }

      if (isDataSourceUriRemote) {
        _initializeLiveServerPatches();
      }

      notifyListeners();
    }();
  }

  Future _loadSelectedDataSource() {
    final future = () async {
      if (isDataSourceUriRemote) {
        await _getDatabaseFromServer(dataSourceUri);
      } else {
        await _loadLocalDBData();
      }
    }();
    loadingService.addFuture(future);
    return future;
  }

  //Writes a patch to local disk and submits it to the server.
  Future newTransaction(Patch patch) {
    final future = () async {
      if (isDataSourceUriRemote) {
        await _postPatchToServer(patch);
      } else {
        // Add this patch to the local DB before saving.
        database.addPatch(patch);
        _santize();
        await writeLocalDiskDatabase(database, dataSourceUri);
      }
      notifyListeners();
    }();
    loadingService.addFuture(future);
    return future;
  }

  Future _loadLocalDBData() async {
    final data =
        await fs.file(Uri.decodeFull(dataSourceUri.toString())).readAsString();

    database = SnoutDB.fromJson(json.decode(data));
    notifyListeners();
  }

  //Used in the UI to see failed and successful patches
  List<String> failedPatches = <String>[];

  bool connected = true;

  //this will load the entire database if it has
  //not been loaded yet, OR it will load only
  //the changes that have been made since it's
  //last download.
  Future _getDatabaseFromServer(Uri source) async {
    // We cannot have multiple instances of this method running at the same time, because right now
    // only the length of the ledger is the only way to check the state, rather than using
    // blockchain tech to properly link the list and maintain state like it really should

    await loadingLock.synchronized(() async {
      final storageKey = base64UrlEncode(utf8.encode(source.toString()));

      final diskData = await readText(storageKey);

      Uri path = Uri.parse('${Uri.decodeFull(source.toString())}/patches');

      if (diskData == null) {
        final newData = await apiClient
            .get(path)
            .timeout(Duration(seconds: 30));

        final List<Patch> patches =
            (json.decode(newData.body) as List)
                .map((e) => Patch.fromJson(e as Map))
                .toList();
        final decodedDatabase = SnoutDB(patches: patches);
        database = decodedDatabase;
        await storeText(
          storageKey,
          json.encode(decodedDatabase.patches.map((e) => e.toJson()).toList()),
        );
        notifyListeners();
        return;
      }

      //Decode as list of patches
      final patches =
          List.from(
            json.decode(diskData) as List,
          ).map((x) => Patch.fromJson(x)).toList();
      final diskDatabase = SnoutDB(patches: patches);

      //Assign to local database so even when it fails to load, we still have
      //the latest disk database
      database = diskDatabase;

      //Load the changest only, since it is more bandwidth efficient
      //and the database is ONLY based on patches.
      final headOriginResult = await apiClient
          .get(Uri.parse('${Uri.decodeFull(source.toString())}/head'))
          .timeout(Duration(seconds: 10));

      final headOrigin = jsonDecode(headOriginResult.body) as int;

      final headLocal = database.patches.length;
      List<Patch> diffPatches = [];
      if (headOrigin > headLocal) {
        // There are new patches, download them.
        for (int i = headLocal; i < headOrigin; i++) {
          final patchResult = await apiClient
              .get(Uri.parse('${Uri.decodeFull(source.toString())}/patches/$i'))
              .timeout(Duration(seconds: 10));
          diffPatches.add(Patch.fromJson(json.decode(patchResult.body)));
        }

        for (final patch in diffPatches) {
          // Add new patches to the database
          database.addPatch(patch);
        }

        _santize();

        // Save new database!
        await storeText(
          storageKey,
          json.encode(database.patches.map((e) => e.toJson()).toList()),
        );
      }
    });

    notifyListeners();
  }

  Future lifecycleListener() async {
    if (isDataSourceUriRemote) {
      await _getDatabaseFromServer(dataSourceUri);
    }
  }

  //Writes a patch to local disk and submits it to the server.
  Future _postPatchToServer(Patch patch) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    try {
      final res = await apiClient
          .put(dataSourceUri, body: json.encode(patch))
          .timeout(Duration(seconds: 15));
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

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;

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

    _channel = WebSocketChannel.connect(
      Uri.parse(
        '${dataSourceUri.toString().startsWith("https") ? "wss" : "ws"}://${dataSourceUri.host}:${dataSourceUri.port}/listen/${dataSourceUri.pathSegments.last}',
      ),
    );

    _channel!.ready.then((_) {
      if (connected == false) {
        //Only do an origin sync if we were previouosly not connected
        //Since the db is syncronized before creating this object
        //we can assume that connection exists for the first reconnect
        //thus connected = true by default
        _getDatabaseFromServer(dataSourceUri);
      }
      connected = true;
      notifyListeners();
    });

    _subscription = _channel!.stream.listen(
      (event) async {
        if (event == "PING") {
          _channel?.sink.add("PONG");
          return;
        }
        if (event == "PONG") {
          // Ignore pong
          return;
        }
        // ignore: avoid_print
        print("new socket message: $event");

        try {
          final decoded = json.decode(event);

          switch (decoded['type'] as String?) {
            case SocketMessageType.newPatchId:
              // There is a new patch, we don't care about actual head value, we will just call the normal loading routine
              _getDatabaseFromServer(dataSourceUri);
              break;
            default:
              Logger.root.warning(
                "unknown socket message: $event",
                StackTrace.current,
              );
              break;
          }
        } catch (e, s) {
          Logger.root.severe("socket parse error", e, s);
        }

        notifyListeners();
      },
      onDone: () {
        connected = false;
        notifyListeners();

        _channel?.sink.close();
        //Re-attempt a connection after some time
        Timer(const Duration(seconds: 3), () {
          if (connected == false) {
            _initializeLiveServerPatches();
          }
        });
      },
      onError: (e) {
        //Dont try and reconnect on an error
        Logger.root.warning("DB Listener Error", e);

        _channel?.sink.close();
        _subscription?.cancel();
        connected = false;
        notifyListeners();
      },
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _channel?.sink.close();
    super.dispose();
  }
}
