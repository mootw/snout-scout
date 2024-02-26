import 'package:flutter/foundation.dart';
import 'package:fs_shim/fs_shim.dart';


final fs = kIsWeb ? fileSystemWeb : fileSystemDefault;
final storePath = fs.directory('/events');

Future storeText(String key, String value) async {
  final file = fs.file('${storePath.path}/$key');
  if(await file.exists() == false) {
    await file.create(recursive: true);
  }
  await file.writeAsString(value, flush: true);
}

Future deleteText(String key) async {
  // and a file in it
  final file = fs.file('${storePath.path}/$key');

  if(await file.exists()) {
    await file.delete();
  }
}

Future<String?> readText(String key) async {
  final file = fs.file('${storePath.path}/$key');

  if (await file.exists()) {
    return await file.readAsString();
  } else {
    return null;
  }
}
