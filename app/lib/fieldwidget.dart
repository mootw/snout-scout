//Ratio of width to height
import 'dart:async';
import 'dart:math' as math;

import 'package:app/main.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:simple_cluster/simple_cluster.dart';
import 'package:snout_db/event/match.dart';
import 'package:snout_db/event/matchevent.dart';
import 'package:snout_db/snout_db.dart';

double mapRatio = 0.5;
double fieldWidthSizeInches = 649;
double robotPorportionalSize = 32 / fieldWidthSizeInches;

class FieldPositionSelector extends StatelessWidget {
  const FieldPositionSelector(
      {super.key,
      required this.onTap,
      required this.robotPosition,
      required this.alliance,
      required this.teamNumber});

  final Function(FieldPosition) onTap;
  final FieldPosition? robotPosition;
  final Alliance alliance;
  final int teamNumber;

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
              FieldMapWidget(),
              if (robotPosition != null)
                Container(
                  alignment: Alignment(
                      robotPosition!.x *
                          (1 +
                              ((robotPorportionalSize * constraints.maxWidth) /
                                  constraints.maxWidth)),
                      -robotPosition!.y *
                          (1 +
                              ((robotPorportionalSize * constraints.maxWidth) /
                                  constraints.maxHeight))),
                  child: Container(
                    alignment: Alignment.center,
                      width: robotPorportionalSize * constraints.maxWidth,
                      height: robotPorportionalSize * constraints.maxWidth,
                      color:
                          alliance == Alliance.red ? Colors.red : Colors.blue,
                      child: Text(teamNumber.toString(),
                          style: TextStyle(
                              fontSize: 13 * (constraints.maxWidth / fieldWidthSizeInches)))),
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
                  FieldMapWidget(),
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
                          ((robotPorportionalSize * constraints.maxWidth) /
                              constraints.maxWidth)),
                  -robotPosition.y *
                      (1 +
                          ((robotPorportionalSize * constraints.maxWidth) /
                              constraints.maxHeight))),
              child: Container(
                alignment: Alignment.center,
                width: robotPorportionalSize * constraints.maxWidth,
                height: robotPorportionalSize * constraints.maxWidth,
                color: match.getAllianceOf(int.parse(team)) == Alliance.red
                    ? Colors.red
                    : Colors.blue,
                child: Text(team,
                    style:
                        TextStyle(fontSize: 13 * (constraints.maxWidth / fieldWidthSizeInches))),
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

  const FieldHeatMap(
      {super.key, required this.events, required this.useRedNormalized});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
        aspectRatio: 1 / mapRatio,
        child: LayoutBuilder(builder: (context, constraints) {
          return Stack(
            children: [
              FieldMapWidget(),
              //Darken the map slightly to create more contrast against the heatmap
              Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.black26),
              CustomPaint(
                size: Size.infinite,
                painter:
                    HeatMap(events: events, useRedNormalized: useRedNormalized),
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
    DBSCAN dbscan = DBSCAN(
      epsilon: robotPorportionalSize / 3 * size.width,
      //Allow for clusters of single points
      minPoints: 1,
    );

    List<List<double>> ls = List.generate(
        events.length,
        (index) => [
              (((useRedNormalized
                              ? events[index].positionTeamNormalized.x
                              : events[index].position.x) +
                          1) /
                      2) *
                  size.width,
              (1 -
                      (((useRedNormalized
                                  ? events[index].positionTeamNormalized.y
                                  : events[index].position.y) +
                              1) /
                          2)) *
                  size.height
            ]);

    final result = dbscan.run(ls);
    //Sort so the smallest render first
    result.sort((a, b) => a.length - b.length);

    //Max group length with a minimum of 4 (to prevent single elements from being red hot)
    int maxGroupLength = result.fold(
        0, (previousValue, element) => math.max(previousValue, element.length));

    for (final group in result) {
      //group contains the index of each element in that group

      Paint p = Paint();
      p.maskFilter =
          MaskFilter.blur(BlurStyle.normal, math.sqrt(group.length) + 2);
      p.color = HSVColor.fromAHSV(
              1, (1 - (group.length / maxGroupLength)) * 225, 1, 1)
          .toColor();
      //Draw more and more green circles with increasing opacity
      canvas.drawCircle(Offset(ls[group[0]][0], ls[group[0]][1]),
          6 + math.sqrt(group.length * 3), p);
    }
  }

  @override
  bool shouldRepaint(HeatMap oldDelegate) => false;
}


class FieldMapWidget extends StatelessWidget {
  const FieldMapWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Image.asset("assets/field_map/${Provider.of<EventDB>(context, listen: false).db.config.season}.png");
  }
}