


import 'package:flutter/foundation.dart';
import 'package:fs_shim/fs_shim.dart';

Future storeText (String key, String value) async {
  final fs = kIsWeb ? fileSystemWeb : fileSystemDefault;

  // Create a top level directory
  final dir = fs.directory('/dir');

  // and a file in it
  final file = fs.file('${dir.path}/$key');

  await file.create(recursive: true);
  await file.writeAsString(value);
}

Future<String?> readText (String key) async {
  final fs = kIsWeb ? fileSystemWeb : fileSystemDefault;

  // Create a top level directory
  final dir = fs.directory('/dir');

  // and a file in it
  final file = fs.file('${dir.path}/$key');

  if(await file.exists()) {
    return await file.readAsString();
  } else {
    return null;
  }
}