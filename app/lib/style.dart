import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:snout_db/snout_db.dart';
import 'dart:math';

// DESIGN GUIDELINES MIN SCREEN WIDTH = 355
// this means that the unfolded z fold could overflow slightly...
// but the intention is to accomodate larger screens sooo
const double minimumWidth = 355;

// https://m3.material.io/foundations/layout/applying-layout/medium
bool isLargeDevice(BuildContext context) => MediaQuery.of(context).size.width > 600;


//Theme data
const primaryColor = Color.fromARGB(255, 49, 219, 43);
final darkScheme =
    ColorScheme.fromSeed(seedColor: primaryColor, brightness: Brightness.dark);
ThemeData defaultTheme =
    ThemeData.from(colorScheme: darkScheme, useMaterial3: true);

const warningColor = Colors.yellow;

/// Returns a UI color for a given alliance.
Color getAllianceColor(Alliance alliance) =>
    alliance == Alliance.red ? Colors.red : Colors.blue;

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

/// standard size for images stored in snout scout
/// (we do not want to store hundreds of MB sized images)
/// for transport efficiency reasons, client performance
/// for image decoding or db file, and data/disk usage.
double scoutImageSize = 800;

/// convenient dialog that will prompt the user to take a new image
/// or select it from their device storage
Future<XFile?> pickOrTakeImageDialog(BuildContext context) async {
  ImageSource? result = await showDialog(
      context: context,
      builder: (dialogContext) => SimpleDialog(
            children: [
              SimpleDialogOption(
                  onPressed: () =>
                      Navigator.of(dialogContext).pop(ImageSource.camera),
                  child: const ListTile(
                    leading: Icon(Icons.camera_alt),
                    title: Text("Camera"),
                  )),
              SimpleDialogOption(
                  onPressed: () =>
                      Navigator.of(dialogContext).pop(ImageSource.gallery),
                  child: const ListTile(
                    leading: Icon(Icons.image),
                    title: Text("Gallery"),
                  )),
                  SimpleDialogOption(
                  onPressed: () =>
                      Navigator.of(dialogContext).pop(null),
                  child: const ListTile(
                    leading: Icon(Icons.close),
                    title: Text("Cancel"),
                  )),
            ],
          ));

  if (result == null) {
    return null;
  }

  final XFile? photo = await ImagePicker().pickImage(
      source: result,
      maxWidth: scoutImageSize,
      maxHeight: scoutImageSize,
      imageQuality: 50);
  return photo;
}
