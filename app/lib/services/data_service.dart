import 'package:fs_shim/fs_shim.dart';

final fs = fileSystemDefault;
final localSnoutDBPath = fs.directory('/events');
final remoteDBPath = fs.directory('/remote');

Future storeText(String key, String value) async {
  final file = fs.file('${remoteDBPath.path}/$key');
  if (await file.exists() == false) {
    await file.create(recursive: true);
  }
  await file.writeAsString(value, flush: true);
}

Future<String?> readText(String key) async {
  final file = fs.file('${remoteDBPath.path}/$key');

  if (await file.exists()) {
    return await file.readAsString();
  } else {
    return null;
  }
}
