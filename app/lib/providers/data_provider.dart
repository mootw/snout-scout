import 'dart:async';

import 'package:app/screens/configure_source.dart';
import 'package:flutter/material.dart';
import 'package:snout_db/event/frcevent.dart';
import 'package:snout_db/patch.dart';

class DataProvider extends ChangeNotifier {



  FRCEvent db = emptyNewEvent;



  DataProvider();

  //Writes a patch to local disk and submits it to the server.
  Future addPatch(Patch patch) async {

    //Apply the patch to the local only if it was successful!
    db = patch.patch(db);
    notifyListeners();
  }
}
