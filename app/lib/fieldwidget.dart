//Ratio of width to height
import 'dart:async';
import 'dart:math' as math;

import 'package:app/main.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:snout_db/event/match.dart';
import 'package:snout_db/season/matchevent.dart';
import 'package:snout_db/snout_db.dart';

double mapRatio = 0.5;

double robotSize = 32 / 649;

class FieldPositionSelector extends StatelessWidget {
  const FieldPositionSelector(
      {super.key, required this.onTap, required this.robotPosition});

  final Function(FieldPosition) onTap;
  final FieldPosition? robotPosition;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1 / mapRatio,
      child: LayoutBuilder(builder: (context, constraints) {
        return GestureDetector(
          onTapDown: (details) {
            onTap(FieldPosition(
                (details.localPosition.dx / constraints.maxWidth * 2) - 1,
                ((1 -
                            details.localPosition.dy /
                                (constraints.maxWidth * mapRatio)) *
                        2) -
                    1));
          },
          child: Stack(
            children: [
              Image.network("$serverURL/field_map.png"),
              if (robotPosition != null)
                Container(
                  alignment: Alignment(
                      robotPosition!.x *
                          (1 +
                              ((robotSize * constraints.maxWidth) /
                                  constraints.maxWidth)),
                      -robotPosition!.y *
                          (1 +
                              ((robotSize * constraints.maxWidth) /
                                  constraints.maxHeight))),
                  child: Container(
                    width: robotSize * constraints.maxWidth,
                    height: robotSize * constraints.maxWidth,
                    color: Colors.black,
                    child: Icon(Icons.smart_toy,
                        size: robotSize * constraints.maxWidth - 2,
                        color: Theme.of(context).colorScheme.primary),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}

class FieldTimelineViewer extends StatefulWidget {
  const FieldTimelineViewer({super.key, required this.match});

  final FRCMatch match;

  @override
  State<FieldTimelineViewer> createState() => _FieldTimelineViewerState();
}

class _FieldTimelineViewerState extends State<FieldTimelineViewer> {
  int _animationTime = 0;
  Timer? _playTimer;
  bool _isPlayingValue = false;
  bool get _isPlaying => _isPlayingValue;
  set _isPlaying(bool newValue) {
    _isPlayingValue = newValue;
    if (newValue) {
      //Increment the animation right away, this makes things feel more responsive.
      _animationTime++;
      _playTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_animationTime < matchLength.inSeconds && mounted) {
          setState(() {
            _animationTime++;
          });
        }
      });
    } else {
      _playTimer?.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AspectRatio(
            aspectRatio: 1 / mapRatio,
            child: LayoutBuilder(builder: (context, constraints) {
              return Stack(
                children: [
                  Image.network("$serverURL/field_map.png"),
                  for (final robot in widget.match.robot.keys)
                    RobotMapEventView(
                        time: _animationTime,
                        match: widget.match,
                        team: robot,
                        isAnimating: _isPlaying),
                ],
              );
            })),
        Row(
          children: [
            IconButton(
                icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                onPressed: () {
                  setState(() {
                    _isPlaying = !_isPlaying;
                  });
                }),
            Expanded(
              child: Slider(
                min: 0,
                max: matchLength.inSeconds.toDouble(),
                divisions: matchLength.inSeconds,
                onChanged: (double value) {
                  setState(() {
                    _animationTime = value.toInt();
                    _isPlaying = false;
                  });
                },
                value: _animationTime.toDouble(),
              ),
            ),
            SizedBox(
                width: 32,
                child: Text(
                  _animationTime.toString(),
                  textAlign: TextAlign.center,
                )),
          ],
        )
      ],
    );
  }
}

class RobotMapEventView extends StatelessWidget {
  const RobotMapEventView(
      {super.key,
      required this.isAnimating,
      required this.time,
      required this.match,
      required this.team});

  final bool isAnimating;
  final int time;
  final String team;
  final FRCMatch match;

  @override
  Widget build(BuildContext context) {
    final posEvent = match.robot[team]!.timelineInterpolated().lastWhereOrNull(
        (event) => event.time <= time && event.id == "robot_position");
    if (posEvent == null) {
      //A position event is required to show the robot on the timeline
      return const SizedBox();
    }
    FieldPosition robotPosition = posEvent.position;

    final allRecentEvents = match.robot[team]!.timelineInterpolated().where(
        (event) =>
            event.time >= time &&
            event.time < time + 2 &&
            event.id != "robot_position");

    return LayoutBuilder(
        key: Key(team),
        builder: (context, constraints) {
          return Stack(children: [
            AnimatedAlign(
              duration: isAnimating
                  ? const Duration(milliseconds: 1000)
                  : const Duration(milliseconds: 100),
              alignment: Alignment(
                  robotPosition.x *
                      (1 +
                          ((robotSize * constraints.maxWidth) /
                              constraints.maxWidth)),
                  -robotPosition.y *
                      (1 +
                          ((robotSize * constraints.maxWidth) /
                              constraints.maxHeight))),
              child: Container(
                alignment: Alignment.center,
                width: robotSize * constraints.maxWidth,
                height: robotSize * constraints.maxWidth,
                color: match.getAllianceOf(int.parse(team)) == Alliance.red
                    ? Colors.red
                    : Colors.blue,
                child: Text(team,
                    style:
                        TextStyle(fontSize: 10 * (constraints.maxWidth / 500))),
              ),
            ),
            for (final event in allRecentEvents)
              Align(
                alignment: Alignment(event.position.x, -event.position.y),
                child: Text(event.label,
                    style: const TextStyle(backgroundColor: Colors.black)),
              ),
          ]);
        });
  }
}

class FieldHeatMap extends StatelessWidget {
  final List<MatchEvent> events;
  final bool useRedNormalized;

  const FieldHeatMap({super.key, required this.events, required this.useRedNormalized});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
        aspectRatio: 1 / mapRatio,
        child: LayoutBuilder(builder: (context, constraints) {
          return Stack(
            children: [
              Image.network("$serverURL/field_map.png"),
              CustomPaint(
                size: Size.infinite,
                painter: HeatMap(events: events, useRedNormalized: useRedNormalized),
              )
            ],
          );
        }));
  }
}

class HeatMap extends CustomPainter {
  List<MatchEvent> events;
  bool useRedNormalized;

  HeatMap({required this.events, required this.useRedNormalized});

  @override
  void paint(Canvas canvas, Size size) {
    Paint p = Paint()..color = Colors.green;
    p.maskFilter =
        MaskFilter.blur(BlurStyle.normal, math.min(events.length * 0.5, 10));

    for (final event in events) {
      Offset offset = Offset(
          (((useRedNormalized
                          ? event.positionTeamNormalized.x
                          : event.position.x) +
                      1) /
                  2) *
              size.width,
          (1 -
                  (((useRedNormalized
                              ? event.positionTeamNormalized.y
                              : event.position.y) +
                          1) /
                      2)) *
              size.height);
      canvas.drawCircle(offset, 5 + math.min(events.length.toDouble(), 10), p);
    }
  }

  @override
  bool shouldRepaint(HeatMap oldDelegate) => false;
}
