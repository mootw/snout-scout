import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';

class KioskProvider extends ChangeNotifier {
  ///whether or not to flip the field image in the match recorder

  Archive kioskData;

  late Map<String, String> encodedModels;
  late Map<String, Uint8List> slideshow;
  late String primaryModel;

  KioskProvider({required this.kioskData}) {
    encodedModels = Map<String, String>.fromEntries(
      kioskData
          .where(
            (e) =>
                e.isFile &&
                e.name.startsWith('${kioskData.first.name}models/') &&
                e.name.endsWith('.glb'),
          )
          .map(
            (e) => MapEntry(
              e.name.split('/').last,
              'data:model/gltf-binary;base64,${base64Encode(e.content)}',
            ),
          ),
    );

    primaryModel = utf8.decode(
      kioskData
          .firstWhere((e) => e.isFile && e.name.endsWith('/primary_model.txt'))
          .content,
    );

    slideshow = Map<String, Uint8List>.fromEntries(
      kioskData
          .where(
            (e) =>
                e.isFile &&
                e.name.startsWith('${kioskData.first.name}slideshow'),
          )
          .map((e) => MapEntry(e.name.split('/').last, e.content)),
    );
  }
}
