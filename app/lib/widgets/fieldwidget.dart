//Ratio of width to height
import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:app/providers/data_provider.dart';
import 'package:app/services/snout_image_cache.dart';
import 'package:app/style.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:simple_cluster/simple_cluster.dart';
import 'package:snout_db/event/match_data.dart';
import 'package:snout_db/event/matchevent.dart';
import 'package:snout_db/event/robot_match_trace.dart';
import 'package:snout_db/snout_chain.dart';

const double mapRatio = 0.5;
const double fieldWidthMeters = 16.48;
const double robotSizeMeters = 0.8;
const double robotFieldProportion = robotSizeMeters / fieldWidthMeters;

//For consistent UI sizing
const double largeFieldSize = 355;
const double smallFieldSize = 255;

/// used on the scouting pages
class FieldPositionSelector extends StatelessWidget {
  const FieldPositionSelector({
    super.key,
    required this.onTap,
    required this.robotPosition,
    required this.alliance,
    required this.teamNumber,
    this.coverAlignment,
  });

  final Function(FieldPosition) onTap;
  final FieldPosition? robotPosition;
  final Alliance alliance;
  final int teamNumber;

  final double? coverAlignment;

  @override
  Widget build(BuildContext context) {
    //We still use the map ratio since The layout builder can be in an unconstrained width
    //when the device is tilted sideways in the match recorder and it can result in
    //weird visuals since none of this is really the best way to do it.
    return AspectRatio(
      aspectRatio: 1 / mapRatio,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return GestureDetector(
            onTapDown: (details) {
              onTap(
                FieldPosition(
                  (details.localPosition.dx / constraints.maxWidth * 2) - 1,
                  ((1 -
                              details.localPosition.dy /
                                  (constraints.maxWidth * mapRatio)) *
                          2) -
                      1,
                ),
              );
            },
            child: FieldMap(
              children: [
                if (coverAlignment != null)
                  Align(
                    alignment: Alignment(coverAlignment!, 0),
                    child: Container(
                      width: constraints.maxWidth / 2,
                      height: double.infinity,
                      color: Colors.black54,
                    ),
                  ),
                if (robotPosition != null)
                  Container(
                    alignment: Alignment(
                      robotPosition!.x *
                          (1 +
                              ((robotFieldProportion * constraints.maxWidth) /
                                  constraints.maxWidth)),
                      -robotPosition!.y *
                          (1 +
                              //Use 1/mapratio for the height since we are ONLY using the width constraint
                              //IDK it seems to work here, not sure why it isn't a problem elseware.
                              (((1 / mapRatio) *
                                      robotFieldProportion *
                                      constraints.maxWidth) /
                                  constraints.maxWidth)),
                    ),
                    child: Container(
                      alignment: Alignment.center,
                      width: robotFieldProportion * constraints.maxWidth,
                      height: robotFieldProportion * constraints.maxWidth,
                      color: getAllianceUIColor(alliance),
                      child: Text(
                        teamNumber.toString(),
                        style: TextStyle(fontSize: 10),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// showed on the match page to see the recording of the match
class FieldTimelineViewer extends StatefulWidget {
  const FieldTimelineViewer({super.key, required this.match});

  final MatchData match;

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
        FieldMap(
          children: [
            for (final robot in widget.match.robot.entries)
              RobotMapEventView(
                time: _animationTime,
                robotRecording: robot.value,
                team: robot.key,
                isAnimating: _isPlaying,
              ),
          ],
        ),
        // TODO in depth timeline here???? like robot: event
        Row(
          children: [
            IconButton(
              icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
              onPressed: () {
                setState(() {
                  _isPlaying = !_isPlaying;
                });
              },
            ),
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
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class RobotMapEventView extends StatelessWidget {
  const RobotMapEventView({
    super.key,
    required this.isAnimating,
    required this.time,
    required this.robotRecording,
    required this.team,
  });

  final bool isAnimating;
  final int time;
  final RobotMatchTraceData robotRecording;
  final String team;

  @override
  Widget build(BuildContext context) {
    final posEvent = robotRecording.timelineInterpolated.lastWhereOrNull(
      (event) => event.time <= time && event.isPositionEvent,
    );
    if (posEvent == null) {
      //A position event is required to show the robot on the timeline
      return const SizedBox();
    }
    FieldPosition robotPosition = posEvent.position;

    final allRecentEvents = robotRecording.timelineInterpolated.where(
      (event) =>
          event.time >= time &&
          event.time < time + 2 &&
          event.isPositionEvent == false,
    );

    return LayoutBuilder(
      key: Key(team),
      builder: (context, constraints) {
        return Stack(
          children: [
            AnimatedAlign(
              duration: isAnimating
                  ? const Duration(milliseconds: 1000)
                  : const Duration(milliseconds: 100),
              alignment: Alignment(
                robotPosition.x *
                    (1 +
                        ((robotFieldProportion * constraints.maxWidth) /
                            constraints.maxWidth)),
                -robotPosition.y *
                    (1 +
                        ((robotFieldProportion * constraints.maxWidth) /
                            constraints.maxHeight)),
              ),
              child: Container(
                alignment: Alignment.center,
                width: robotFieldProportion * constraints.maxWidth,
                height: robotFieldProportion * constraints.maxWidth,
                color: getAllianceUIColor(robotRecording.alliance),
                child: Text(team, style: TextStyle(fontSize: 10)),
              ),
            ),
            for (final event in allRecentEvents)
              Align(
                alignment: Alignment(event.position.x, -event.position.y),
                child: Text(
                  event.getLabelFromConfig(
                    context.watch<DataProvider>().event.config,
                  ),
                  style: const TextStyle(backgroundColor: Colors.black),
                ),
              ),
          ],
        );
      },
    );
  }
}

class FieldHeatMap extends StatelessWidget {
  final List<MatchEvent> events;
  final double size;

  const FieldHeatMap({
    super.key,
    required this.events,
    this.size = smallFieldSize,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints.loose(Size(size, size / 2)),
      child: FullScreenFieldSelector(
        child: FieldMap(
          //size: size,
          children: [
            Container(color: Colors.black12),
            CustomPaint(
              size: Size.infinite,
              painter: HeatMap(events: events),
            ),
          ],
        ),
      ),
    );
  }
}

class FullScreenFieldSelector extends StatelessWidget {
  final Widget child;
  final Widget? showAbove;

  const FullScreenFieldSelector({
    super.key,
    required this.child,
    this.showAbove,
  });

  @override
  Widget build(BuildContext context) {
    if (showAbove != null) {
      return Stack(
        children: [
          InkWell(
            child: child,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => Scaffold(
                    appBar: AppBar(),
                    body: Stack(children: [child, showAbove!]),
                  ),
                ),
              );
            },
          ),
          showAbove!,
        ],
      );
    }
    return InkWell(
      child: child,
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => Scaffold(appBar: AppBar(), body: child),
          ),
        );
      },
    );
  }
}

class PathsViewer extends StatefulWidget {
  final List<({String label, List<MatchEvent> path})> paths;
  final bool emphasizeStartPoint;
  final bool useRedNormalized;
  final double size;

  const PathsViewer({
    super.key,
    required this.paths,
    this.size = largeFieldSize,
    this.emphasizeStartPoint = true,
    this.useRedNormalized = true,
  });

  @override
  State<PathsViewer> createState() => _PathsViewerState();
}

class _PathsViewerState extends State<PathsViewer> {
  int filterIndex = -1;

  int viewMode = 1; //0 = paths only, 1 = overlay text

  @override
  Widget build(BuildContext context) {
    final List<({String label, List<MatchEvent> path})> filteredPaths;
    if (filterIndex == -1) {
      filteredPaths = widget.paths;
    } else {
      filteredPaths = [widget.paths[filterIndex]];
    }

    return ConstrainedBox(
      constraints: BoxConstraints.loose(Size(widget.size, double.infinity)),
      child: Column(
        children: [
          ConstrainedBox(
            constraints: BoxConstraints.loose(
              Size(widget.size, widget.size / 2),
            ),
            child: FullScreenFieldSelector(
              showAbove: null,
              child: FieldMap(
                children: [
                  Container(color: Colors.black12),
                  for (final path in filteredPaths) ...[
                    CustomPaint(
                      size: Size.infinite,
                      painter: MapLine(
                        emphasizeStartPoint: widget.emphasizeStartPoint,
                        color: getColorFromIndex(filteredPaths.indexOf(path)),
                        events: path.path,
                      ),
                    ),
                  ],
                  // Event Labels
                  if (viewMode == 1)
                    Stack(
                      children: [
                        for (final path in filteredPaths)
                          for (final event in path.path.where(
                            (event) => !event.isPositionEvent,
                          ))
                            Align(
                              alignment: Alignment(
                                event.position.x,
                                -event.position.y,
                              ),
                              child: Text(
                                event.getLabelFromConfig(
                                  context.watch<DataProvider>().event.config,
                                ),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  backgroundColor: Colors.black26,
                                ),
                              ),
                            ),
                      ],
                    ),

                  if (viewMode == 2)
                    Align(
                      alignment: Alignment.topRight,
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final path in filteredPaths)
                              for (final event in path.path.where(
                                (event) => !event.isPositionEvent,
                              ))
                                Text(
                                  '${event.time} ${event.getLabelFromConfig(context.watch<DataProvider>().event.config)}',
                                  style: TextStyle(
                                    color: getColorFromIndex(
                                      filteredPaths.indexOf(path),
                                    ),
                                    backgroundColor: Colors.black26,
                                  ),
                                ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomLeft,
            child: Container(
              color: Colors.black87,
              height: 32,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  TextButton(
                    child: Text("M$viewMode"),
                    onPressed: () => setState(() {
                      setState(() {
                        if (viewMode == 0) {
                          viewMode = 1;
                        } else if (viewMode == 1) {
                          viewMode = 2;
                        } else {
                          viewMode = 0;
                        }
                      });
                    }),
                  ),
                  TextButton(
                    onPressed: () => setState(() {
                      filterIndex = -1;
                    }),
                    child: const Text("All"),
                  ),
                  for (final (idx, item) in widget.paths.indexed)
                    TextButton(
                      onPressed: () => setState(() {
                        filterIndex = idx;
                      }),
                      child: Text(
                        item.label,
                        style: TextStyle(
                          color: getColorFromIndex(widget.paths.indexOf(item)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HeatMap extends CustomPainter {
  List<MatchEvent> events;

  HeatMap({required this.events});

  @override
  void paint(Canvas canvas, Size size) {
    DBSCAN dbscan = DBSCAN(
      epsilon: robotFieldProportion / 5 * size.width,
      //Allow for clusters of single points
      minPoints: 1,
    );

    List<List<double>> ls = List.generate(
      events.length,
      (index) => [
        ((events[index].position.x + 1) / 2) * size.width,
        (1 - ((events[index].position.y + 1) / 2)) * size.height,
      ],
    );

    final result = dbscan.run(ls);
    //Sort so the smallest render first
    result.sort((a, b) => a.length - b.length);

    //Max group length with a minimum of 4 (to prevent single elements from being red hot)
    int maxGroupLength = result.fold(
      0,
      (previousValue, element) => math.max(previousValue, element.length),
    );

    for (final group in result) {
      //group contains the index of each element in that group

      Paint p = Paint();
      p.maskFilter = MaskFilter.blur(
        BlurStyle.normal,
        math.sqrt(group.length * 0.1) + 1,
      );
      //Make the intensity of each dot based on the amount of events within its approximate area

      p.color = HSVColor.fromAHSV(
        math.min(1, math.max(((group.length + 1) / maxGroupLength), 0.3)),
        100,
        1,
        1,
      ).toColor();
      //Draw more and more green circles with increasing opacity
      canvas.drawCircle(
        Offset(ls[group[0]][0], ls[group[0]][1]),
        4 + math.sqrt(group.length * 0.5),
        p,
      );
    }
  }

  @override
  bool shouldRepaint(HeatMap oldDelegate) =>
      Object.hashAll(oldDelegate.events) != Object.hashAll(events);
}

/// Renders a line with a color over the surface
class MapLine extends CustomPainter {
  Color color;
  List<MatchEvent> events;
  bool emphasizeStartPoint;

  MapLine({
    required this.events,
    required this.emphasizeStartPoint,
    this.color = Colors.green,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (events.isEmpty) {
      return;
    }
    Paint p = Paint();
    p.color = color;
    p.strokeWidth = 3;
    p.strokeCap = StrokeCap.round;
    p.style = PaintingStyle.stroke;

    Path path = Path();

    final startingPosition = getFieldPosition(events.first, size);
    path.moveTo(startingPosition[0], startingPosition[1]);
    for (final event in events) {
      final pos1 = getFieldPosition(event, size);
      if (event.isPositionEvent) {
        path.lineTo(pos1[0], pos1[1]);
      } else {
        canvas.drawCircle(Offset(pos1[0], pos1[1]), 1.5, p);
      }
    }
    canvas.drawPath(path, p);

    p.style = PaintingStyle.fill;

    if (emphasizeStartPoint) {
      canvas.drawCircle(Offset(startingPosition[0], startingPosition[1]), 6, p);
    }
  }

  // Returns [x, y]
  getFieldPosition(MatchEvent event, Size renderSize) {
    return [
      ((event.position.x + 1) / 2) * renderSize.width,
      (1 - ((event.position.y + 1) / 2)) * renderSize.height,
    ];
  }

  @override
  bool shouldRepaint(MapLine oldDelegate) =>
      Object.hashAll(oldDelegate.events) != Object.hashAll(events);
}

/// Widget that holds a field image and displays stuff on top of it
class FieldMap extends StatelessWidget {
  final List<Widget> children;
  final double size;

  //Displays a field map with overlays.
  const FieldMap({super.key, required this.children, this.size = 1200});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints.loose(Size(size, size / 2)),
      child: AspectRatio(
        aspectRatio: 1 / mapRatio,
        child: Stack(children: [const FieldImage(), ...children]),
      ),
    );
  }
}

class FieldImage extends StatelessWidget {
  const FieldImage({super.key});

  @override
  Widget build(BuildContext context) {
    String fieldImage = context.watch<DataProvider>().event.config.fieldImage;
    if (fieldImage == '') {
      fieldImage =
          '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';
    }
    return Image(
      image: snoutImageCache.getCached(base64Decode(fieldImage)),
      fit: BoxFit.contain,
      width: 2000,
    );
  }
}
