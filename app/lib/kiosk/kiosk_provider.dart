import 'package:archive/archive.dart';
import 'package:flutter/material.dart';

class KioskProvider extends ChangeNotifier {
  ///whether or not to flip the field image in the match recorder

  Archive kioskData;

  KioskProvider({required this.kioskData});
}
