import 'package:flutter/material.dart';
import 'package:snout_db/snout_db.dart';
import 'dart:math';

//Theme data
const primaryColor = Color.fromARGB(255, 49, 219, 43);
final darkScheme =
    ColorScheme.fromSeed(seedColor: primaryColor, brightness: Brightness.dark);
ThemeData defaultTheme =
    ThemeData.from(colorScheme: darkScheme, useMaterial3: true);


/// Returns a UI color for a given alliance.
Color getAllianceColor (Alliance alliance) => alliance == Alliance.red ? Colors.red : Colors.blue;

/// Generates a 'random' color from an index
Color getColorFromIndex(int index) =>
    HSVColor.fromAHSV(1, (100 + (index * pi * 10000)) % 360, 0.8, 0.7)
        .toColor();


Color colorFromHex(String hexString) {
  final hexCode = hexString.replaceAll('#', '');
  return Color(int.parse('FF$hexCode', radix: 16));
}


Future<String?> showStringInputDialog(
    BuildContext context, String label, String currentValue) async {
  final myController = TextEditingController(text: currentValue);
  return await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(label),
          content: TextField(
            controller: myController,
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(null),
            ),
            TextButton(
              child: const Text('Save'),
              onPressed: () => Navigator.of(context).pop(myController.text),
            ),
          ],
        );
      });
}
