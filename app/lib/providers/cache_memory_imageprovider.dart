// This is used to cache byte images for better performance
// Copied from here, but modified to automatically detect the image file
// hashing just needs to be reasonably faster than re-decoding the image data (especially since these images are shown many times)
// https://stackoverflow.com/questions/67963713/how-to-cache-memory-image-using-image-memory-or-memoryimage-flutter
// https://gist.github.com/darmawan01/9be266df44594ea59f07032e325ffa3b

import 'dart:convert' as convert;
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

class CacheMemoryImageProvider extends ImageProvider<CacheMemoryImageProvider> {
  final String imageDataStringBase64;
  final String tag;

  CacheMemoryImageProvider(this.imageDataStringBase64)
    : tag = imageDataStringBase64.substring(0, 64);

  @override
  ImageStreamCompleter loadImage(
    CacheMemoryImageProvider key,
    ImageDecoderCallback decode,
  ) {
    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(decode),
      scale: 1.0,
      debugLabel: tag,
      informationCollector: () sync* {
        yield ErrorDescription('Tag: $tag');
      },
    );
  }

  Future<Codec> _loadAsync(ImageDecoderCallback decode) async {
    // the DefaultCacheManager() encapsulation, it get cache from local storage.

    final Uint8List bytes = convert.base64Decode(imageDataStringBase64);

    if (bytes.lengthInBytes == 0) {
      // The file may become available later.
      PaintingBinding.instance.imageCache.evict(this);
      throw StateError('$tag is empty and cannot be loaded as an image.');
    }
    final buffer = await ImmutableBuffer.fromUint8List(bytes);

    return await decode(buffer);
  }

  @override
  Future<CacheMemoryImageProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<CacheMemoryImageProvider>(this);
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) return false;
    bool res =
        other is CacheMemoryImageProvider &&
        other.imageDataStringBase64 == imageDataStringBase64;
    return res;
  }

  @override
  int get hashCode => imageDataStringBase64.hashCode;

  @override
  String toString() =>
      '${objectRuntimeType(this, 'CacheImageProvider')}("$tag")';
}
