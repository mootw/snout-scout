import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String flipFieldImagePrefs = 'flipFieldImage';

/// stores local preferences like whether to flip the field map image
class LocalConfigProvider extends ChangeNotifier {
  ///whether or not to flip the field image in the match recorder
  bool flipFieldImage = false;

  LocalConfigProvider() {
    () async {
      final prefs = await SharedPreferences.getInstance();
      flipFieldImage = prefs.getBool(flipFieldImagePrefs) ?? false;
    }();
  }

  Future setFlipFieldImage(bool newFlipFieldImage) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool(flipFieldImagePrefs, newFlipFieldImage);
    flipFieldImage = newFlipFieldImage;
    notifyListeners();
  }
}
