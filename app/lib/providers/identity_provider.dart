

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';


String unknownIdentity = "unknown";

class IdentityProvider extends ChangeNotifier {

  String identity = unknownIdentity;

  IdentityProvider () {
    () async {
      final prefs = await SharedPreferences.getInstance();
      identity = prefs.getString("scout_identity") ?? unknownIdentity;
    }();
  }

  Future setIdentity (String newIdentity) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString("scout_identity", newIdentity);
    identity = newIdentity;
    notifyListeners();
  }

}