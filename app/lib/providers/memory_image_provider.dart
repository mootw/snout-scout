import 'dart:ui';
import 'dart:ui_web';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_avif/flutter_avif.dart';

/// Based on [MemoryAvifImage] from flutter_avif and [MemoryImage] from flutter framework
/// Handles overriding for specific browsers, otherwise passes through to native decoders
/// https://gist.github.com/darmawan01/9be266df44594ea59f07032e325ffa3b
class CachedMemoryImageAvif extends ImageProvider<CachedMemoryImageAvif> {
  final String tag;
  final Uint8List bytes;
  final int overrideDurationMs;

  final double scale = 1.0;

  CachedMemoryImageAvif({
    required this.tag,
    required this.bytes,
    this.overrideDurationMs = -1,
  });

  @override
  ImageStreamCompleter loadImage(
    CachedMemoryImageAvif key,
    ImageDecoderCallback decode,
  ) {
    if (bytes.length > 16 &&
        isAvifFile(bytes.sublist(0, 16)) == AvifFileType.avif) {
      // Override for browsers that do not support AVIF natively
      // TODO bug with google chrome: https://github.com/flutter/flutter/issues/160600
      // TODO safari(webkit) supports AVIF since iOS 16.
      //  This can be removed once most devices are on iOS 16 (https://iosref.com/ios-usage)
      if (BrowserDetection.instance.browserEngine == BrowserEngine.blink ||
          BrowserDetection.instance.browserEngine == BrowserEngine.webkit) {
        return AvifImageStreamCompleter(
          key: key,
          codec: _loadAsyncAvif(key, decode),
          scale: key.scale,
          debugLabel: 'MemoryAvifImage(${key.tag})',
        );
      }
    }

    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(decode),
      scale: key.scale,
      debugLabel: tag,
      informationCollector: () sync* {
        yield ErrorDescription('Tag: $tag');
      },
    );
  }

  Future<Codec> _loadAsync(ImageDecoderCallback decode) async {
    // the DefaultCacheManager() encapsulation, it get cache from local storage.
    final Uint8List bytes = this.bytes;

    if (bytes.lengthInBytes == 0) {
      // The file may become available later.
      PaintingBinding.instance.imageCache.evict(this);
      throw StateError('$tag is empty and cannot be loaded as an image.');
    }
    final buffer = await ImmutableBuffer.fromUint8List(bytes);

    return await decode(buffer);
  }

  Future<AvifCodec> _loadAsyncAvif(
    CachedMemoryImageAvif key,
    ImageDecoderCallback decode,
  ) async {
    final bytesUint8List = bytes.buffer.asUint8List(0);
    final fType = isAvifFile(bytesUint8List.sublist(0, 16));
    if (fType == AvifFileType.unknown) {
      throw StateError('Loaded file is not an avif file.');
    }

    final codec = fType == AvifFileType.avif
        ? SingleFrameAvifCodec(bytes: bytesUint8List)
        : MultiFrameAvifCodec(
            key: hashCode,
            avifBytes: bytesUint8List,
            overrideDurationMs: overrideDurationMs,
          );
    await codec.ready();

    return codec;
  }

  @override
  Future<CachedMemoryImageAvif> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<CachedMemoryImageAvif>(this);
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is CachedMemoryImageAvif &&
        other.tag == tag &&
        other.scale == scale;
  }

  @override
  int get hashCode => tag.hashCode;

  @override
  String toString() =>
      'CachedMemoryImageAvif("$tag")';
}
