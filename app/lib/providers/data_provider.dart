import 'dart:async';
import 'dart:math';

import 'package:app/screens/configure_source.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snout_db/event/frcevent.dart';
import 'package:snout_db/patch.dart';
import 'package:snout_db/snout_db.dart';

String getRandomIdentity() => Random().nextBool()
    ? "fred"
    : Random().nextBool()
        ? "sophie"
        : Random().nextBool()
            ? "scott"
            : "alexander the great";

/// determines how the app should load data and apply changes
enum DataSource {
  memory(jsonValue: 'memory'),
  localDisk(jsonValue: 'localDisk'),
  remoteServer(jsonValue: 'remoteServer');

  const DataSource({
    required this.jsonValue,
  });

  final String jsonValue;
  String toJson() => jsonValue;

  factory DataSource.fromJson(String data) {
    for (final item in DataSource.values) {
      if (item.jsonValue == data) {
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

      prefs.getString("");

      notifyListeners();
    }();
  }

  /// Changing the data source requires a few things
  /// depending on the source
  Future setDataSource(DataSource newSource) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString("dataSource", newSource.toString());

    notifyListeners();
  }

  //Writes a patch to local disk and submits it to the server.
  Future submitPatch(Patch patch) async {
    switch (dataSource) {
      case DataSource.memory:
        database.addPatch(patch);
        break;
      case DataSource.localDisk:
        database.addPatch(patch);
        break;
      case DataSource.remoteServer:
        database.addPatch(patch);
        break;
    }

    notifyListeners();
  }
}
