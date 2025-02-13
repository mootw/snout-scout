import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui_web';

import 'package:flutter/material.dart';
import 'package:flutter_avif/flutter_avif.dart';

SnoutImageCache snoutImageCache = SnoutImageCache();

/// TODO clear out this image cache if it gets too large
/// i should use the flutter image cache (like the old memory image provider)
/// but right now i need to use an intermediate layer
class SnoutImageCache {
  final _images = <int, Uint8List>{};

  void clear() {
    _images.clear();
  }

  Uint8List _getBytesCached(String data) {
    final image = _images[data.hashCode];
    if (image != null) {
      return image;
    } else {
      final decoded = base64Decode(data);
      _images[data.hashCode] = decoded;
      return decoded;
    }
  }

  ImageProvider getCached(String data) {
    final bytes = _getBytesCached(data);

    // TODO bug with google chrome (works in firefox): https://github.com/flutter/flutter/issues/160600
    if (BrowserDetection.instance.browserEngine == BrowserEngine.blink) {
      // Detect if Image is avif and use the compatibility decoder which is likely slower
      // than the platform decoder. This entire check can be removed once 160600 is fixed
      if (isAvifFile(bytes.sublist(0, 16)) == AvifFileType.avif) {
        return MemoryAvifImage(bytes);
      } else {
        return MemoryImage(bytes);
      }
    }
    return MemoryImage(bytes);
  }
}
