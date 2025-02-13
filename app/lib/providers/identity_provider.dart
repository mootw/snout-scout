import 'package:flutter/material.dart';

class IdentityProvider extends ChangeNotifier {
  String identity = "unkown";

  IdentityProvider();

  Future setIdentity(String newIdentity) async {
    identity = newIdentity;
    notifyListeners();
  }
}
