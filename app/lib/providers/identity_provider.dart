import 'package:flutter/material.dart';
import 'package:snout_db/pubkey.dart';

class IdentityProvider extends ChangeNotifier {
  Pubkey? identity;

  IdentityProvider();

  Future setIdentity(Pubkey newIdentity) async {
    identity = newIdentity;
    notifyListeners();
  }
}
