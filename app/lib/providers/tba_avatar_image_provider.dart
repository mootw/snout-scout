import 'dart:convert' as convert;
import 'dart:ui';
import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:fs_shim/fs_shim.dart';

final fs = fileSystemDefault;
final avatarCache = fs.directory('/avatar_cache');

class TBAAvatarImageProvider extends ImageProvider<TBAAvatarImageProvider> {
  final int team;
  final int year;
  final String tbaSecretKey;

  final String tag; //the cache id use to get cache

  TBAAvatarImageProvider(this.team, this.year, this.tbaSecretKey)
    : tag = '${year}_$team';

  @override
  ImageStreamCompleter loadImage(
    TBAAvatarImageProvider key,
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

  // TODO This code is jank and does not nicely handle errors / generic avatars
  Future<Codec> _loadAsync(ImageDecoderCallback decode) async {
    final file = fs.file('${avatarCache.path}/${year}_$team');

    final cacheOnly = await file.exists() == true
        ? await file.readAsBytes()
        : null;
    if (cacheOnly != null) {
      if (cacheOnly.lengthInBytes > 0) {
        // Continue loading data again if the cache file exists and is empty
        final buffer = await ImmutableBuffer.fromUint8List(cacheOnly);
        return await decode(buffer);
      } else {
        throw StateError(
          'Cache image $tag exists but is empty! This means the team has no avatar',
        );
      }
    }

    final url =
        'https://www.thebluealliance.com/api/v3/team/frc$team/media/$year';
    final headers = {'X-TBA-Auth-Key': tbaSecretKey};
    final response = await http.get(Uri.parse(url), headers: headers);

    if (response.statusCode != 200) {
      // RETURN GENERIC
      PaintingBinding.instance.imageCache.evict(this);
      throw StateError(
        'Network request: $url: ${response.statusCode}. ${response.body}',
      );
    }

    final mediaList = convert.json.decode(response.body) as List<dynamic>;
    final avatar = mediaList.firstWhereOrNull((e) => e['type'] == 'avatar');
    if (avatar != null) {
      final imageData = convert.base64Decode(avatar['details']['base64Image']);
      final buffer = await ImmutableBuffer.fromUint8List(imageData);
      // Write cache!
      if (await file.exists() == false) {
        await file.create(recursive: true);
      }
      await file.writeAsBytes(imageData);
      return await decode(buffer);
    }

    // Write the cache file as empty, because this team has no avatar
    if (await file.exists() == false) {
      await file.create(recursive: true);
    }

    throw StateError('$tag has invalid data!');
  }

  @override
  Future<TBAAvatarImageProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<TBAAvatarImageProvider>(this);
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) return false;
    bool res = other is TBAAvatarImageProvider && other.tag == tag;
    return res;
  }

  @override
  int get hashCode => tag.hashCode;

  @override
  String toString() =>
      '${objectRuntimeType(this, 'TBAAvatarImageProvider')}("$tag")';
}
