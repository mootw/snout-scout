import 'dart:async';
import 'dart:convert';

import 'package:app/api.dart';
import 'package:app/screens/configure_source.dart';
import 'package:flutter/material.dart';
import 'package:snout_db/event/frcevent.dart';
import 'package:snout_db/patch.dart';

class DataProvider extends ChangeNotifier {



  FRCEvent db = emptyNewEvent;



  DataProvider() {
    () async {
      final data = await apiClient.get(Uri.parse("http://localhost:6749/events/2023mnmi2.json"));

      db = FRCEvent.fromJson(jsonDecode(data.body));
      notifyListeners();
    }();
  }

  //Writes a patch to local disk and submits it to the server.
  Future addPatch(Patch patch) async {

    //Apply the patch to the local only if it was successful!
    db = patch.patch(db);
    notifyListeners();
  }
}
