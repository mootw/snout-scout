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
import 'package:synchronized/synchronized.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

// Immediately save transaction to disk, then try and send the oldest transaction to the server
// If that fails, exponential back-off (resets on app instance)
// There is a separate outbox for each source
class PatchOutbox {
  final Uri source;
  final commitLock = Lock();

  List<String> outboxCache = [];

  late Function notifyListeners;

  /// Only one instance of the outbox can exist at the same time per uri
  /// Otherwise behavior will be unexpected
  PatchOutbox(this.source, this.notifyListeners);

  Future init() async {
    final prefs = await SharedPreferences.getInstance();
    outboxCache = prefs.getStringList(outboxKey) ?? [];
    notifyListeners();
  }

  String get outboxKey =>
      'outbox:${base64Encode(utf8.encode(source.toString()))}';

  Future clearOutbox() async {
    outboxCache = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(outboxKey, []);
    notifyListeners();
  }

  Future newPatch(Patch patch) async {
    // First save patch to disk asap, we can complete the future now and be certain of no data loss
    final prefs = await SharedPreferences.getInstance();
    final outbox = prefs.getStringList(outboxKey) ?? [];
    outbox.add(jsonEncode(patch.toJson()));
    outboxCache = outbox;
    await prefs.setStringList(outboxKey, outbox);
    notifyListeners();
    // Then submit patches
    commitPatchs();
  }

  Future commitPatchs() async {
    await commitLock.synchronized(() async {
      // Notify listeners that an outbox commit attempt is started.
      notifyListeners();
      final prefs = await SharedPreferences.getInstance();
      final outbox = prefs.getStringList(outboxKey) ?? [];
      if (outbox.isEmpty) {
        Logger.root.warning('Tried to commit an empty outbox');
      }
      final patch = outbox[0];
      try {
        final res = await apiClient
            .put(source, body: patch)
            .timeout(Duration(seconds: 30));
        if (res.statusCode == 200) {
          // Success
          outbox.removeAt(0);
          await prefs.setStringList(outboxKey, outbox);
          outboxCache = List.of(outbox);
          notifyListeners();

          // TODO commit remaining patches if there are more left
        } else {
          throw Exception(
            'Failed to upload patch ${res.statusCode} ${res.body}',
          );
        }
      } catch (e) {
        Logger.root.severe('failed to upload patch $e');
      }
    });
  }

  void dispose() {}
}

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
  final List<String>? safeIds;

  final _loadingLock = Lock();

  // Disgusting way to handle paths but it works so whatever
  bool get isDataSourceUriRemote => dataSourceUri.toString().startsWith('http');

  late final PatchOutbox remoteOutbox;

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
    // This is expensive and slow (because it's hacky) so only run it in kiosk mode.
    if (safeIds != null) {
      // Remove pitscouting data
      database.event.pitscouting.forEach(
        (team, value) =>
            value.removeWhere((key, value) => safeIds!.contains(key) == false),
      );
      database.event.config.pitscouting.removeWhere(
        (e) => safeIds!.contains(e.id) == false,
      );

      // Remove match scouting survey data
      database.event.matches.forEach(
        (matchKey, match) => match.robot.forEach(
          (teamKey, robotData) => robotData.survey.removeWhere(
            (key, value) => safeIds!.contains(key) == false,
          ),
        ),
      );
      database.event.config.matchscouting.survey.removeWhere(
        (item) => safeIds!.contains(item.id) == false,
      );

      // Remove match properties data
      database.event.matches.forEach(
        (matchKey, match) => match.properties?.removeWhere(
          (key, value) => safeIds!.contains(key) == false,
        ),
      );
      database.event.config.matchscouting.properties.removeWhere(
        (e) => safeIds!.contains(e.id) == false,
      );

      // Remove match process data
      database.event.config.matchscouting.processes.removeWhere(
        (e) => safeIds!.contains(e.id) == false,
      );
    }
  }

  SnoutDB get database {
    return _database;
  }

  bool isInitialLoad = false;

  FRCEvent get event => database.event;

  DataProvider(this.dataSourceUri, [this.safeIds]) {
    () async {
      remoteOutbox = PatchOutbox(dataSourceUri, () => notifyListeners());
      await remoteOutbox.init();

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
        await remoteOutbox.newPatch(patch);
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

  bool connected = true;

  //this will load the entire database if it has
  //not been loaded yet, OR it will load only
  //the changes that have been made since it's
  //last download.
  Future _getDatabaseFromServer(Uri source) async {
    // We cannot have multiple instances of this method running at the same time, because right now
    // only the length of the ledger is the only way to check the state, rather than using
    // blockchain tech to properly link the list and maintain state like it really should

    await _loadingLock.synchronized(() async {
      final storageKey = base64UrlEncode(utf8.encode(source.toString()));

      // Database is stored on disk as just an array of patches
      String? diskData = await readText(storageKey);

      if (diskData == null) {
        Uri path = Uri.parse('${Uri.decodeFull(source.toString())}/patches');
        final newData = await apiClient
            .get(path)
            .timeout(Duration(seconds: 30));

        final List<Patch> patches =
            (json.decode(newData.body) as List)
                .map((e) => Patch.fromJson(e as Map))
                .toList();
        final decodedDatabase = SnoutDB(patches: patches);
        database = decodedDatabase;
        _santize();
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

      //Load the changest only, since it is more bandwidth efficient
      //and the database is ONLY based on patches.
      final headOriginResult = await apiClient
          .get(Uri.parse('${Uri.decodeFull(source.toString())}/head'))
          .timeout(Duration(seconds: 10));

      final headOrigin = jsonDecode(headOriginResult.body) as int;

      final headLocal = patches.length;
      if (headOrigin > headLocal) {
        // There are new patches, download them.
        for (int i = headLocal; i < headOrigin; i++) {
          final patchResult = await apiClient
              .get(Uri.parse('${Uri.decodeFull(source.toString())}/patches/$i'))
              .timeout(Duration(seconds: 10));

          if (patchResult.statusCode != 200) {
            throw Exception(
              'Failed to download patch $i ${patchResult.statusCode} ${patchResult.body}',
            );
          }
          final patch = Patch.fromJson(json.decode(patchResult.body));
          patches.add(patch);
          // Save new database! This allows for incremental updates. It hurts download performance
          // but each patch is immediately saved to disk
          await storeText(
            storageKey,
            json.encode(patches.map((e) => e.toJson()).toList()),
          );
          print('downloaded $i of ${headOrigin - headLocal} patches');
        }

        //Assign to local database so even when it fails to load, we still have
        //the latest disk database
        database = SnoutDB(patches: patches);
        ;
        _santize();
      }
    });

    notifyListeners();
  }

  Future lifecycleListener() async {
    if (isDataSourceUriRemote) {
      await _getDatabaseFromServer(dataSourceUri);
    }
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
    remoteOutbox.dispose();
    super.dispose();
  }
}
