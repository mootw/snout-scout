import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:app/api.dart';
import 'package:app/providers/client_snout_db.dart';
import 'package:app/providers/loading_status_service.dart';
import 'package:app/services/data_service.dart';
import 'package:cbor/cbor.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:server/socket_messages.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snout_db/actions/write_config.dart';
import 'package:snout_db/event/frcevent.dart';
import 'package:snout_db/message.dart';
import 'package:snout_db/snout_chain.dart';
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

  Future remove(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      outboxKey,
      prefs.getStringList(outboxKey)?.where((e) => e != value).toList() ?? [],
    );
    notifyListeners();
  }

  Future writeNewMessage(SignedChainMessage message) async {
    // First save patch to disk asap, we can complete the future now and be certain of no data loss
    final prefs = await SharedPreferences.getInstance();
    final outbox = prefs.getStringList(outboxKey) ?? [];
    outbox.add(base64Encode(cbor.encode(message.toCbor())));
    outboxCache = outbox;
    await prefs.setStringList(outboxKey, outbox);
    notifyListeners();
    // Then submit patches
    commitActions();
  }

  Future commitActions() async {
    await commitLock.synchronized(() async {
      // Notify listeners that an outbox commit attempt is started.
      notifyListeners();
      final prefs = await SharedPreferences.getInstance();
      final outbox = prefs.getStringList(outboxKey) ?? [];
      if (outbox.isEmpty) {
        Logger.root.warning('Tried to commit an empty outbox');
      }
      final action = base64Decode(outbox[0]);
      try {
        final res = await apiClient
            .put(source, body: action)
            .timeout(Duration(seconds: 30));
        if (res.statusCode == 200) {
          // Success
          outbox.removeAt(0);
          await prefs.setStringList(outboxKey, outbox);
          outboxCache = List.of(outbox);
          notifyListeners();
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
Future writeLocalDiskDatabase(SnoutDBFile db, Uri path) async {
  final file = fs.file(Uri.decodeFull(path.toString()));
  if (await file.exists() == false) {
    await file.create(recursive: true);
  }
  await file.writeAsBytes(Uint8List.fromList(cbor.encode(db.toCbor())));
}

/// To be used within the context of a single data source
class DataProvider extends ChangeNotifier {
  final Uri dataSourceUri;
  final bool kioskMode;

  final _loadingLock = Lock();

  // Disgusting way to handle paths but it works so whatever
  bool get isDataSourceUriRemote => dataSourceUri.toString().startsWith('http');

  late final PatchOutbox remoteOutbox;

  //Initialize the database as empty
  //this value should get quickly overwritten
  //i just dont like this being nullable is all.
  SnoutChain _database = SnoutChain([]);

  set database(SnoutChain newDatabase) {
    _database = newDatabase;
    _sanitize();
    isInitialLoad = true;
  }

  void _sanitize() {
    // This is expensive and slow (because it's hacky) so only run it in kiosk mode.
    if (kioskMode) {
      // Since the kiosk mode overwrites the database, we must  grab the config from the actions list manually
      final configAction = database.actions.lastWhereOrNull(
        (e) => e.payload.action is ActionWriteConfig,
      );
      final config =
          (configAction?.payload.action as ActionWriteConfig?)?.config;

      final List<String> safeIds = config == null
          ? []
          : [
              ...config.pitscouting
                  .where((e) => e.isSensitiveField == false)
                  .map((e) => e.id),
              ...config.matchscouting.properties
                  .where((e) => e.isSensitiveField == false)
                  .map((e) => e.id),
              ...config.matchscouting.survey
                  .where((e) => e.isSensitiveField == false)
                  .map((e) => e.id),
              ...config.matchscouting.processes
                  .where((e) => e.isSensitiveField == false)
                  .map((e) => e.id),
            ];

      // Remove data items by key ids
      database.event.dataItems.removeWhere(
        (e, s) => safeIds.contains(s.$1.key) == false,
      );

      database.event.config.pitscouting.removeWhere(
        (e) => safeIds.contains(e.id) == false,
      );
      database.event.config.matchscouting.survey.removeWhere(
        (item) => safeIds.contains(item.id) == false,
      );
      database.event.config.matchscouting.properties.removeWhere(
        (e) => safeIds.contains(e.id) == false,
      );
      // Remove match process data
      database.event.config.matchscouting.processes.removeWhere(
        (e) => safeIds.contains(e.id) == false,
      );
    }
  }

  SnoutChain get database {
    return _database;
  }

  bool isInitialLoad = false;

  FRCEvent get event => database.event;

  DataProvider(this.dataSourceUri, [this.kioskMode = false]) {
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
  Future newTransaction(SignedChainMessage message) {
    final future = () async {
      if (isDataSourceUriRemote) {
        await remoteOutbox.writeNewMessage(message);
      } else {
        // Add this patch to the local DB before saving.
        database.verifyApplyAction(message);
        _sanitize();
        await writeLocalDiskDatabase(
          SnoutDBFile(actions: database.actions),
          dataSourceUri,
        );
      }
      notifyListeners();
    }();
    loadingService.addFuture(future);
    return future;
  }

  Future _loadLocalDBData() async {
    final data = await fs
        .file(Uri.decodeFull(dataSourceUri.toString()))
        .readAsBytes();

    database = SnoutChain.fromFile(
      SnoutDBFile.fromCbor(cbor.decode(data) as CborMap),
    );
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
    // tech to properly link the list and maintain state like it really should

    await _loadingLock.synchronized(() async {
      final storageKey = base64UrlEncode(utf8.encode(source.toString()));

      // Client stores data in a map format on disk.
      Uint8List? diskData = await readBytes(storageKey);

      ClientSnoutDb? clientDb;

      if (diskData != null) {
        // ive played these games before
        clientDb = ClientSnoutDb.fromCbor(cbor.decode(diskData) as CborMap);
        database = clientDb.toDbFile();
        notifyListeners();
      } else {
        // new database! do an initial full sync, this is one network request
        // This is problematic if a device has a poor connection

        final data = await apiClient.get(
          Uri.parse(Uri.decodeFull(source.toString())),
        );

        final remoteDb = SnoutChain.fromFile(
          SnoutDBFile.fromCbor(cbor.decode(data.bodyBytes) as CborMap),
        );

        clientDb = ClientSnoutDb(messageHashes: [], messages: {});
        clientDb.messageHashes = await Future.wait(
          remoteDb.actions.map((e) => e.hash),
        );
        clientDb.messages = Map.fromEntries(
          await Future.wait(
            remoteDb.actions.map(
              (e) async => MapEntry(base64UrlEncode(await e.hash), e),
            ),
          ),
        );
        database = clientDb.toDbFile();
        // Store up-to-date database
        await storeBytes(
          storageKey,
          Uint8List.fromList(cbor.encode(clientDb.toCbor())),
        );
        notifyListeners();
        return;
      }

      // Get index from origin
      // Index is in the form of a json list of message hashes encoded in url safe base64
      final indexResult = await apiClient
          .get(Uri.parse('${Uri.decodeFull(source.toString())}/index'))
          .timeout(Duration(seconds: 20));

      clientDb.messageHashes = (json.decode(indexResult.body) as List)
          .map<List<int>>((e) => base64Url.decode(e as String))
          .toList();

      // Store the updated database index immediately!
      await storeBytes(
        storageKey,
        Uint8List.fromList(cbor.encode(clientDb.toCbor())),
      );

      // Find missing messages
      final missingMessageHashes = clientDb.messageHashes
          .where(
            (e) => clientDb!.messages.containsKey(base64Url.encode(e)) == false,
          )
          .toList();

      for (final messageHash in missingMessageHashes) {
        final messageResult = await apiClient
            .get(
              Uri.parse(
                '${Uri.decodeFull(source.toString())}/messages/${base64Url.encode(messageHash)}',
              ),
            )
            .timeout(Duration(seconds: 10));

        if (messageResult.statusCode != 200) {
          throw Exception(
            'Failed to download message ${base64Url.encode(messageHash)} ${messageResult.statusCode} ${messageResult.body}',
          );
        }

        final decoded = SignedChainMessage.fromCbor(
          cbor.decode(messageResult.bodyBytes) as CborMap,
        );

        clientDb.messages[base64Url.encode(messageHash)] = decoded;
      }
      // Store up-to-date database
      await storeBytes(
        storageKey,
        Uint8List.fromList(cbor.encode(clientDb.toCbor())),
      );
      database = clientDb.toDbFile();
      notifyListeners();
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
        Timer(const Duration(seconds: 17), () {
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
