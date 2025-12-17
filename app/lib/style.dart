import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_avif/flutter_avif.dart';
import 'package:image_picker/image_picker.dart';
import 'package:snout_db/snout_db.dart';
import 'dart:math';

// DESIGN GUIDELINES MIN SCREEN WIDTH = 355
// this means that the unfolded z fold could overflow slightly...
// but the intention is to accomodate larger screens sooo
const double minimumWidth = 355;

// https://m3.material.io/foundations/layout/applying-layout/medium
bool isLargeDevice(BuildContext context) =>
    MediaQuery.of(context).size.width > 600;

// Allow slightly wide to be considered vertical for foldable devices or near-square devices
bool isWideScreen(BuildContext context) =>
    MediaQuery.of(context).size.aspectRatio > 1.2;

//Theme data
const primaryColor = Color.fromARGB(255, 6, 98, 3);
final darkScheme = ColorScheme.fromSeed(
  seedColor: primaryColor,
  brightness: Brightness.dark,
);
ThemeData defaultTheme = ThemeData.from(
  colorScheme: darkScheme,
  useMaterial3: true,
);

const warningColor = Colors.yellow;

/// Returns a UI color for a given alliance. If null, it returns null
Color? getAllianceUIColor(Alliance? alliance) => alliance == null
    ? null
    : (alliance == Alliance.red ? Colors.red : Colors.blue);

/// Generates a 'random' color from an index
Color getColorFromIndex(int index) => HSVColor.fromAHSV(
  1,
  (100 + (index * pi * 10000)) % 360,
  0.8,
  0.7,
).toColor();

Color colorFromHex(String hexString) {
  final hexCode = hexString.replaceAll('#', '');
  return Color(int.parse('FF$hexCode', radix: 16));
}

Future<String?> showStringInputDialog(
  BuildContext context,
  String label,
  String currentValue,
) async {
  final myController = TextEditingController(text: currentValue);
  return await showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(label),
        content: TextField(controller: myController),
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
    },
  );
}

/// standard size for images stored in snout scout
/// client performance (no thumbnails are used atm)
/// for image decoding or db file.
const double defaultImageSize = 1200;

/// convenient dialog that will prompt the user to take a new image
/// or select it from their device storage
Future<Uint8List?> pickOrTakeImageDialog(
  BuildContext context, [
  double imageSize = defaultImageSize,
]) async {
  ImageSource? result = await showDialog(
    context: context,
    builder: (dialogContext) => SimpleDialog(
      children: [
        SimpleDialogOption(
          onPressed: () => Navigator.of(dialogContext).pop(ImageSource.camera),
          child: const ListTile(
            leading: Icon(Icons.camera_alt),
            title: Text("Camera"),
          ),
        ),
        SimpleDialogOption(
          onPressed: () => Navigator.of(dialogContext).pop(ImageSource.gallery),
          child: const ListTile(
            leading: Icon(Icons.image),
            title: Text("Gallery"),
          ),
        ),
        SimpleDialogOption(
          onPressed: () => Navigator.of(dialogContext).pop(null),
          child: const ListTile(
            leading: Icon(Icons.close),
            title: Text("Cancel"),
          ),
        ),
      ],
    ),
  );

  if (result == null) {
    return null;
  }

  final XFile? photo = await ImagePicker().pickImage(
    source: result,
    maxWidth: imageSize,
    maxHeight: imageSize,
  );

  if (photo == null) {
    return null;
  }

  // prefer flutter native UI decoder, as it is likely to be the highest compatibility
  // final codec = await ui.instantiateImageCodec(await photo.readAsBytes());
  // final inputImage = (await codec.getNextFrame()).image;

  // // final inputImage = img.decodeImage(await photo.readAsBytes());

  // final loaded = img.Image.fromBytes(
  //     numChannels: 4,
  //     // This WILL crush HDR images into SDR. Which is fine.
  //     bytes: (await inputImage.toByteData(format: ui.ImageByteFormat.rawRgba))!
  //         .buffer,
  //     width: inputImage.width,
  //     height: inputImage.height);

  // TODO scale the image here rather than in the image picker.
  // final scaledImage = copyResize(inputImage!, width: 200);

  // https://github.com/yekeskin/flutter_avif/issues/39#issuecomment-1858844793
  // https://web.dev/articles/compress-images-avif
  // https://github.com/yekeskin/flutter_avif/issues/70
  final avifFile = await encodeAvif(
    await photo.readAsBytes(),
    // 0 (slowest/highest quality) - 10 (fastest/lowest quality)
    speed: 6,
    // 0 (lossless) - 63 (lowest quality)
    maxQuantizer: 46,
    minQuantizer: 40,
  );
  return avifFile;
}
