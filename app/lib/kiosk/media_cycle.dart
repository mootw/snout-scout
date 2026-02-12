import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:mime/mime.dart';
import 'package:video_player/video_player.dart';
import 'package:web/web.dart' as web;

class MediaCycle extends StatefulWidget {
  const MediaCycle({super.key, required this.media});

  final Map<String, Uint8List> media;

  @override
  State<MediaCycle> createState() => _MediaCycleState();
}

class _MediaCycleState extends State<MediaCycle> {
  int _index = 0;
  Timer? _timer;

  Map<String, String> blobUrls = {};

  VideoPlayerController? _videoPlayer;

  String? mime;

  @override
  void initState() {
    super.initState();

    _changeSlide();

    _timer = Timer.periodic(Duration(seconds: 10), (timer) async {});
  }

  void _changeSlide() {
    _timer?.cancel();

    setState(() {
      _index = (_index + 1) % widget.media.length;
    });

    final value = widget.media.entries.toList()[_index];

    mime = lookupMimeType(
      value.key,
      headerBytes: value.value.take(defaultMagicNumbersMaxLength).toList(),
    );

    // Create Blobs
    if (blobUrls.containsKey(value.key) == false) {
      final bytes = value.value.buffer.toJS;
      final blob = web.Blob([bytes].toJS, web.BlobPropertyBag());

      final blobUrl = web.URL.createObjectURL(blob);
      blobUrls[value.key] = blobUrl;
    }

    _videoPlayer?.dispose();

    if (mime?.startsWith('video') == true) {
      _videoPlayer =
          VideoPlayerController.networkUrl(Uri.parse(blobUrls[value.key]!))
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
    for (final url in blobUrls.values) {
      web.URL.revokeObjectURL(url);
    }
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

    if (mime == null) {
      return Text('File not recognized ${value.key}');
    }
    if (mime?.startsWith('image') == true) {
      return Image.memory(value.value, fit: BoxFit.contain);
    } else if (mime?.startsWith('video') == true) {
      if (_videoPlayer == null || _videoPlayer!.value.isInitialized == false) {
        return Text('Loading ${value.key}...');
      } else {
        return VideoPlayer(_videoPlayer!);
      }
    } else {
      return Text('Unsupported file ${value.key}');
    }
  }
}
