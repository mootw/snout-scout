import 'package:app/providers/data_provider.dart';
import 'package:app/providers/tba_avatar_image_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:web/web.dart' as web;

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
        child: Image(
          errorBuilder: (context, error, stackTrace) =>
              Image.asset('default_team_avatar.png'),
          image: TBAAvatarImageProvider(
            teamNumber,
            year,
            context.read<DataProvider>().event.config.tbaSecretKey!,
          ),
        ),
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
