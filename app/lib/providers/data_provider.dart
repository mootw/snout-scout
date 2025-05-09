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
import 'package:snout_db/db.dart';
import 'package:snout_db/event/frcevent.dart';
import 'package:snout_db/patch.dart';
import 'package:snout_db/snout_db.dart';
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

  // Disgusting way to handle paths but it works so whatever
  bool get isDataSourceUriRemote => dataSourceUri.toString().startsWith('http');

  //Initialize the database as empty
  //this value should get quickly overwritten
  //i just dont like this being nullable is all.
  SnoutDB _database = SnoutDB(
    patches: [
      Patch(
        /// Trick to get around the temporary database lol
        /// This is super duper uber cursed. Basically
        /// It is this to show a "loading..." chip in the UI
        /// because right now the app loads the database after
        /// displaying the dialog for selecting the scout
        /// when it should really load the database before that...
        identity: 'Loading...',
        path: Patch.buildPath(['']),
        time: DateTime.now(),
        value: emptyNewEvent.toJson(),
      ),
    ],
  );

  set database(SnoutDB newDatabase) {
    _database = newDatabase;
    isInitialLoad = true;
  }

  SnoutDB get database {
    return _database;
  }

  bool isInitialLoad = false;

  FRCEvent get event => database.event;

  DataProvider(this.dataSourceUri) {
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
        await _getDatabaseFromServer();
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

  List<({String identity, String status, DateTime time})> scoutStatus = [];

  //this will load the entire database if it has
  //not been loaded yet, OR it will load only
  //the changes that have been made since it's
  //last download.
  Future _getDatabaseFromServer() async {
    final storageKey = base64UrlEncode(utf8.encode(dataSourceUri.toString()));

    final diskData = await readText(storageKey);

    Uri path = Uri.parse('${Uri.decodeFull(dataSourceUri.toString())}/patches');

    if (diskData == null) {
      //Load the changest only, since it is more bandwidth efficient
      //and the database is ONLY based on patches.
      final newData = await apiClient.get(path).timeout(Duration(seconds: 15));

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
    Uri diffPath = Uri.parse(
      '${Uri.decodeFull(dataSourceUri.toString())}/patchDiff',
    );
    final diffResult = await apiClient
        .get(
          diffPath,
          headers: {"head": diskDatabase.patches.length.toString()},
        )
        .timeout(Duration(seconds: 15));

    List<Patch> diffPatches =
        (json.decode(diffResult.body) as List<dynamic>)
            .map((e) => Patch.fromJson(e as Map))
            .toList();

    if (diffPatches.isNotEmpty) {
      // update local with new patches ONLY if it is not empty
      // since instantiating a SnoutDB is SLOW
      database = SnoutDB(patches: [...diskDatabase.patches, ...diffPatches]);
      await storeText(
        storageKey,
        json.encode(database.patches.map((e) => e.toJson()).toList()),
      );
    }

    notifyListeners();
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
        _getDatabaseFromServer();
      }
      connected = true;
      notifyListeners();
    });

    _subscription = _channel!.stream.listen(
      (event) async {
        // ignore: avoid_print
        print("new socket message: $event");

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
              // This is due to time of arrival and whatnot...
              final patch = Patch.fromJson(decoded['patch']);

              //TODO do not send patches over the websocket connection, this is potentially SLOW
              // instead just send a small bit of text signifying that a patch has been uploaded, and then
              // use the standard routine to get the data.

              //Do not add a patch that exists already
              //TODO make the server not send the patch back to the client that sent it, duh
              if (database.patches.any(
                    (item) =>
                        json.encode(item.toJson()) ==
                        json.encode(patch.toJson()),
                  ) ==
                  false) {
                database.addPatch(patch);
              }
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
