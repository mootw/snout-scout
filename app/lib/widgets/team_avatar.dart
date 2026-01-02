import 'dart:convert';

import 'package:app/providers/data_provider.dart';
import 'package:app/services/snout_image_cache.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:provider/provider.dart';
import 'package:web/web.dart' as web;
import 'package:http/http.dart' as http;

/// Loads avatar from https://www.thebluealliance.com/avatars
/// caches the file for offline use
/// https://github.com/the-blue-alliance/the-blue-alliance/issues/8738
class FRCTeamAvatar extends StatelessWidget {
  final int teamNumber;

  final double? size;

  const FRCTeamAvatar({super.key, required this.teamNumber, this.size = 14});

  @override
  Widget build(BuildContext context) {
    final year = DateTime.now().year;

    if (context.read<DataProvider>().event.config.tbaSecretKey?.isNotEmpty ==
        true) {
      return SizedBox(
        width: size,
        height: size,
        child: _TBATeamAvatar(team: teamNumber, year: year),
      );
    }

    // CDN fallback if no tba key is provided!
    final url =
        'https://www.thebluealliance.com/avatar/$year/frc$teamNumber.png';
    if (kIsWeb) {
      return SizedBox(
        width: size,
        height: size,
        child: HtmlElementView.fromTagName(
          tagName: 'img',
          onElementCreated: (Object image) {
            image as web.HTMLImageElement;
            image.src = url;
          },
        ),
      );
    } else {
      return CachedNetworkImage(
        errorWidget: (context, url, error) =>
            Image.asset('default_team_avatar.png'),
        imageUrl:
            'https://www.thebluealliance.com/avatar/$year/frc$teamNumber.png',
        width: size,
        height: size,
      );
    }
  }
}

final manager = CacheManager(Config('tbaAvatarCache'));

class _TBATeamAvatar extends StatefulWidget {
  const _TBATeamAvatar({super.key, required this.team, required this.year});

  final int team;
  final int year;

  @override
  State<_TBATeamAvatar> createState() => _TBATeamAvatarState();
}

class _TBATeamAvatarState extends State<_TBATeamAvatar> {
  Uint8List? _imageData;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final snoutData = context.read<DataProvider>();
    final url =
        'https://www.thebluealliance.com/api/v3/team/frc${widget.team}/media/${widget.year}';

    final headers = {'X-TBA-Auth-Key': snoutData.event.config.tbaSecretKey!};

    final cacheOnly = await manager.getFileFromCache(url);
    if (cacheOnly != null) {
      final avatar = await cacheOnly.file.readAsString();
      final imageData = decodeImage(avatar);
      if (imageData != null) {
        if (mounted) {
          setState(() {
            _imageData = imageData;
          });
        }
      } else {
        final data = await _genericAvatar();
        if (mounted) {
          setState(() {
            _imageData = data;
          });
        }
      }
      return;
    }

    final response = await http.get(Uri.parse(url), headers: headers);

    if (response.statusCode != 200) {
      final data = await _genericAvatar();
      if (mounted) {
        setState(() {
          _imageData = data;
        });
      }
      return;
    }

    final image = await manager.putFile(
      url,
      response.bodyBytes,
      maxAge: Duration(days: 30),
    );

    final avatar = await image.readAsString();
    final imageData = decodeImage(avatar);
    if (imageData != null) {
      if (mounted) {
        setState(() {
          _imageData = imageData;
        });
      }
      return;
    }
    final data = await _genericAvatar();
    if (mounted) {
      setState(() {
        _imageData = data;
      });
    }
  }

  Future<Uint8List> _genericAvatar() async {
    return Uint8List.sublistView(
      await rootBundle.load('default_team_avatar.png'),
    );
  }

  Uint8List? decodeImage(String data) {
    final mediaList = json.decode(data) as List<dynamic>;
    final avatar = mediaList.firstWhereOrNull((e) => e['type'] == 'avatar');
    return avatar == null
        ? null
        : base64Decode(avatar['details']['base64Image']);
  }

  @override
  Widget build(BuildContext context) {
    return _imageData != null
        ? Image(image: memoryImageProvider(_imageData!))
        : SizedBox();
  }
}
