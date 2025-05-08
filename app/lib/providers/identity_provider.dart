import 'package:flutter/material.dart';

class IdentityProvider extends ChangeNotifier {
  String identity = 'unknown';

  IdentityProvider();

  Future setIdentity(String newIdentity) async {
    identity = newIdentity;
    notifyListeners();
  }
}
