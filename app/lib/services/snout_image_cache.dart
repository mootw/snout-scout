import 'dart:convert';
import 'dart:typed_data';

import 'package:app/providers/memory_image_provider.dart';
import 'package:flutter/material.dart';

ImageProvider memoryImageProvider(Uint8List bytes) {
  // final key = sha256.convert(Uint8List.fromList(bytes)).toString();
  // TODO more robust key generation to avoid collisions. Maybe use DataItem key + version?
  // TODO this also will crash if there arent at least 128 bytes
  final key = base64Encode(bytes.sublist(16, 128));
  // return NetworkImage('https://upload.wikimedia.org/wikipedia/commons/7/70/Example.png');
  return CachedMemoryImageAvif(tag: key, bytes: bytes);
}
