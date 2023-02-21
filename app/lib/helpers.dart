import 'package:flutter/material.dart';
import 'package:snout_db/snout_db.dart';

//Theme data
const primaryColor = Color.fromARGB(255, 49, 219, 43);
final darkScheme =
    ColorScheme.fromSeed(seedColor: primaryColor, brightness: Brightness.dark);
ThemeData defaultTheme =
    ThemeData.from(colorScheme: darkScheme, useMaterial3: true);


/// Returns a UI color for a given alliance.
Color getAllianceColor (Alliance alliance) => alliance == Alliance.red ? Colors.red : Colors.blue;