import 'dart:convert';
import 'dart:js_interop';

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:mime/mime.dart';
import 'package:web/web.dart' as web;

class KioskProvider extends ChangeNotifier {
  ///whether or not to flip the field image in the match recorder

  Archive kioskFiles;

  late Map<String, String> encodedModels;

  late Map<String, ({String mime, String uri})> slideshowBlobs;

  late String primaryModel;

  KioskProvider({required this.kioskFiles}) {
    encodedModels = Map<String, String>.fromEntries(
      kioskFiles
          .where(
            (e) =>
                e.isFile &&
                e.name.startsWith('${kioskFiles.first.name}models/') &&
                (e.name.endsWith('.glb') || e.name.endsWith('.gltf')),
          )
          .map((e) {
            final bytes = e.content.buffer.toJS;
            final blob = web.Blob([bytes].toJS, web.BlobPropertyBag());
            final blobUrl = web.URL.createObjectURL(blob);

            return MapEntry(e.name.split('/').last, blobUrl);
          }),
    );

    primaryModel = utf8.decode(
      kioskFiles
          .firstWhere((e) => e.isFile && e.name.endsWith('/primary_model.txt'))
          .content,
    );

    slideshowBlobs = Map<String, ({String mime, String uri})>.fromEntries(
      kioskFiles
          .where(
            (e) =>
                e.isFile &&
                e.name.startsWith('${kioskFiles.first.name}slideshow'),
          )
          .map((e) {
            final mime = lookupMimeType(
              e.name,
              headerBytes: e.content
                  .take(defaultMagicNumbersMaxLength)
                  .toList(),
            );

            // Register a blob URL for the browser to play this media.
            // This is necessary because the media is stored in an archive and not as a separate file that can be accessed via a normal URL.
            final bytes = e.content.buffer.toJS;
            final blob = web.Blob([bytes].toJS, web.BlobPropertyBag());
            final blobUrl = web.URL.createObjectURL(blob);

            return MapEntry(e.name.split('/').last, (
              mime: mime ?? 'application/octet-stream',
              uri: blobUrl,
            ));
          }),
    );
  }

  @override
  void dispose() {
    for (final url in slideshowBlobs.values.map((e) => e.uri)) {
      web.URL.revokeObjectURL(url);
    }
    for (final model in encodedModels.values) {
      web.URL.revokeObjectURL(model);
    }
    super.dispose();
  }
}
