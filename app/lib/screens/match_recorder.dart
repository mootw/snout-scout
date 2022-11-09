import 'dart:async';

import 'package:app/main.dart';
import 'package:app/scouting_tools/scouting_tool.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:snout_db/event/pitscoutresult.dart';
import 'package:snout_db/event/robotmatchresults.dart';
import 'dart:math' as math;


import 'package:snout_db/season/matchevent.dart';

class MatchRecorderPage extends StatefulWidget {
  final String title;

  const MatchRecorderPage({required this.title, Key? key}) : super(key: key);

  @override
  State<MatchRecorderPage> createState() => _MatchRecorderPageState();
}

//Match duration = 150
//The delay between teleop and auto are ignored
//because the time resolution is 1 second.

enum MatchMode { PRE_GAME, AUTO, TELEOP, FINISHED }

//Number between 0 and 1 on both axis
//Positive X is towards the opposing alliance.
//Positive Y is along the alliance wall
//Map is the field boundry.
// (0, 0) is the corner to the left and closest
// to the scoring table.
class RobotPosition {
  double x;
  double y;

  RobotPosition(double posX, double posY)
      : x = (posX * 1000).roundToDouble() / 1000,
        y = (posY * 1000).roundToDouble() / 1000;
}

class _MatchRecorderPageState extends State<MatchRecorderPage> {
  MatchMode _mode = MatchMode.PRE_GAME;

  List<MatchEvent> events = [];

  PitScoutResult postGameSurvey = {};

  get scoutingEvents => _mode == MatchMode.AUTO || _mode == MatchMode.PRE_GAME
      ? Provider.of<SnoutScoutData>(context, listen: false).season.matchscouting.auto
      : _mode == MatchMode.TELEOP
          ? Provider.of<SnoutScoutData>(context, listen: false).season.matchscouting.teleop
          : [];

  //Time = 0 is reserved for pre-game like robot position.
  int _time = 0;

  double mapRotation = 0;

  Timer? t;

  @override
  void dispose() {
    t?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
  }

  Widget getEventButton(MatchEvent tool) {
    return Card(
      child: MaterialButton(
        onPressed: () {
          setState(() {
            if (_mode != MatchMode.PRE_GAME) {
              events
                  .add(MatchEvent.fromEventWithTime(time: _time, event: tool));
            }
          });
        },
        child: Text(tool.label),
      ),
    );
  }

  List<Widget> getTimeline() {
    return [
      IconButton(
          onPressed: () {
            setState(() {
              mapRotation += math.pi;
            });
          },
          icon: Icon(Icons.rotate_right)),
      Container(
          width: double.infinity,
          height: 50,
          alignment: Alignment.center,
          child: const Text("Start of Timeline")),
      for (final item in events.toList()) ...[
        const Divider(height: 0),
        Padding(
          padding: const EdgeInsets.only(left: 12, right: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(item.time.round().toString()),
              Text(item.label),
              IconButton(
                color: Theme.of(context).colorScheme.error,
                icon: const Icon(Icons.remove),
                onPressed: () {
                  setState(() {
                    events.remove(item);
                  });
                },
              ),
            ],
          ),
        ),
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.title}"),
      ),
      body: Flex(
        direction: Axis.vertical,
        children: [
          Expanded(
            child: ListView(
              reverse: true,
              children: getTimeline().reversed.toList(),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            constraints: const BoxConstraints(maxHeight: 300),
            child: Transform.rotate(
              angle: mapRotation,
              child: FieldMapViewer(
                robotPosition: () {
                  MatchEvent? lastMoveEvent = events.toList().lastWhereOrNull((event) => event.id == "robot_position");
                  if(lastMoveEvent != null) {
                    return RobotPosition(lastMoveEvent.getNumber("x"), lastMoveEvent.getNumber("y"));
                  }
                }(),
                onTap: (robotPosition) {
                  setState(() {
                    for (final event in events.toList()) {
                      if (event.id == "robot_position") {
                        //Is position event
                        if (event.time == _time) {
                          print("time is the same");
                          //Event is the same time, overrwite
                          events.remove(event);
                        }
                      }
                    }
                    events.add(MatchEvent.robotPositionEvent(
                        time: _time, x: robotPosition.x, y: robotPosition.y));
                  });
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Time: $_time"),
                const SizedBox(width: 12),
                Text(_mode == MatchMode.PRE_GAME
                    ? "Waiting to start"
                    : _mode == MatchMode.AUTO
                        ? "Auto"
                        : _mode == MatchMode.TELEOP
                            ? "Teleop"
                            : _mode == MatchMode.FINISHED
                                    ? "Finished"
                                    : "Unknown State"),
                const SizedBox(width: 12),
                FilledButton.tonal(
                  onPressed: () {
                    ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(
                        content: Text("Long press to move to next section")));
                  },
                  onLongPress: () async {
                    print(_mode);
                    if (_mode == MatchMode.FINISHED) {
                      //Submit results to server
                      Navigator.pop(context, RobotMatchResults(timeline: events, survey: postGameSurvey));
                    }
                    if (_mode == MatchMode.TELEOP) {
                      //Stop timer
                      t?.cancel();
                      _mode = MatchMode.FINISHED;
                      for (var event in events) {
                        //Scale times between 15 seconds and 150 seconds
                        if (event.time > 15) {
                          num offsetTime = event.time - 15;
                          event.time =
                              (15 + ((offsetTime / (_time - 15)) * 135))
                                  .round();
                        }
                      }

                      _time = 150;
                    }
                    if (_mode == MatchMode.AUTO) {
                      _mode = MatchMode.TELEOP;
                      //Scale auto times
                      for (var event in events) {
                        //Scale times to 15 seconds
                        event.time = ((event.time / _time) * 15).round();
                      }
                      //Set time to 15 if auto was recorded faster than real time.
                      if (_time < 15) {
                        _time = 15;
                      }
                    }
                    if (_mode == MatchMode.PRE_GAME) {
                      _mode = MatchMode.AUTO;
                      _time = 1; //Second 0 is reserved for pre-game events
                      //Start timer
                      t = Timer.periodic(const Duration(seconds: 1), (timer) {
                        if (_mode != MatchMode.FINISHED) {
                          setState(() {
                            _time++;
                          });
                        }
                      });
                    }
                    setState(() {});
                  },
                  //Start recording
                  //Teleop
                  //Finish recording
                  child: Text(
                      "${_mode == MatchMode.PRE_GAME ? "Start Recording" : _mode == MatchMode.AUTO ? "Teleop" : _mode == MatchMode.TELEOP ? "Finish Recordig" : "Save"}"),
                ),
              ],
            ),
          ),
          Wrap(
            children: [
              for (int i = 0; i < scoutingEvents.length; i++)
                SizedBox(
                  height: 69,
                  width: (MediaQuery.of(context).size.width / 3) -
                      1, // -1 for some layout padding.
                  child: getEventButton(scoutingEvents[i]),
                ),
            ],
          ),
          if(_mode == MatchMode.FINISHED)
            ListView(
        shrinkWrap: true,
        children: [
          for (var item in Provider.of<SnoutScoutData>(context, listen: false).season.matchscouting.postgame)
            Container(
                padding: const EdgeInsets.all(12),
                child: ScoutingToolWidget(
                  tool: item,
                  survey: postGameSurvey,
                )),
        ],
      )
        ],
      ),
    );
  }
}




//Ratio of width to height
double mapRatio = 0.5;

double robotSize = 32 / 649;

//General display widget for a field.
///NOTE: DO NOT constrain this widget, as it will lose its aspect ratio
class FieldMapViewer extends StatelessWidget {
  final Function(RobotPosition) onTap;

  final RobotPosition? robotPosition;

  const FieldMapViewer(
      {required this.onTap, this.robotPosition, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    //Limit the view to the aspect ratio of the map
    //to prevent layout or touch detection oddity.
    return AspectRatio(
      aspectRatio: 1 / mapRatio,
      child: LayoutBuilder(builder: (context, constraints) {
        return SizedBox(
          child: GestureDetector(
            onTapDown: (details) {
              onTap(RobotPosition(
                  details.localPosition.dx / constraints.maxWidth,
                  1 -
                      details.localPosition.dy /
                          (constraints.maxWidth * mapRatio)));
            },
            child: Stack(
              children: [
                Center(
                  child: Image.network("$serverURL/field_map.png"),
                ),
                if (robotPosition != null)
                  Container(
                    alignment: Alignment(
                        ((robotPosition!.x * 2) - 1) *
                            (1 + ((robotSize * constraints.maxWidth) / constraints.maxWidth)),
                        -((robotPosition!.y * 2) - 1) *
                            (1 + ((robotSize * constraints.maxWidth) / constraints.maxHeight))),
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
          ),
        );
      }),
    );
  }
}