import 'dart:typed_data';

import 'package:fs_shim/fs_shim.dart';

final fs = fileSystemDefault;
final localSnoutDBPath = fs.directory('/events');
final remoteDBPath = fs.directory('/remote');

Future<Uint8List?> readBytes(String key) async {
  final file = fs.file('${remoteDBPath.path}/$key');

  if (await file.exists()) {
    return await file.readAsBytes();
  } else {
    return null;
  }
}

Future<void> storeBytes(String key, Uint8List bytes) async {
  final file = fs.file('${remoteDBPath.path}/$key');
  if (await file.exists() == false) {
    await file.create(recursive: true);
  }
  await file.writeAsBytes(bytes, flush: true);
}
