import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class MediaCycle extends StatefulWidget {
  const MediaCycle({super.key, required this.media});

  final Map<String, ({String mime, String uri})> media;

  @override
  State<MediaCycle> createState() => _MediaCycleState();
}

class _MediaCycleState extends State<MediaCycle> {
  int _index = 0;
  Timer? _timer;

  // So just reusing one controller and disposing it makes sure that the video always starts
  // at the beginning. tried using a map and loading all of them only once, but could not
  // get consistent play performance. i think that is due to the viewer being un-interactable
  // when not visible. even though i am disposing it it leaks somehow...
  VideoPlayerController? _videoPlayer;

  @override
  void initState() {
    super.initState();
    _changeSlide();
  }

  void _changeSlide() {
    _timer?.cancel();

    setState(() {
      _index = (_index + 1) % widget.media.length;
    });

    final value = widget.media.entries.toList()[_index];

    if (value.value.mime.startsWith('video') == true) {
      _videoPlayer?.dispose();

      _videoPlayer =
          VideoPlayerController.networkUrl(Uri.parse(value.value.uri))
            ..initialize().then((_) {
              _timer = Timer(
                _videoPlayer?.value.duration ?? Duration(seconds: 10),
                () {
                  _changeSlide();
                },
              );
              // Ensure the first frame is shown after the video is initialized, even before the play button has been pressed.
              setState(() {});
            });
      // Start playing the video
      _videoPlayer?.play();
    } else {
      final timeout = Duration(seconds: 10);

      _timer = Timer(timeout, () {
        _changeSlide();
      });
    }
  }

  @override
  void dispose() {
    _videoPlayer?.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.media.isEmpty) {
      return Text('No media to display /slideshow');
    }

    final isCurrent = ModalRoute.of(context)?.isCurrent ?? false;
    if (!isCurrent) {
      return Text('Media is paused because this page is not currently visible');
    }

    final value = widget.media.entries.toList()[_index];

    if (value.value.mime.startsWith('image') == true) {
      return Image.network(value.value.uri, fit: BoxFit.contain);
    } else if (value.value.mime.startsWith('video') == true) {
      final player = _videoPlayer;
      if (player == null || player.value.isInitialized == false) {
        return Text('Loading ${value.key}...');
      } else {
        return VideoPlayer(player);
      }
    } else {
      return Text('Unsupported file ${value.key}');
    }
  }
}
