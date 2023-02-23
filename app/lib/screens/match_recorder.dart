import 'dart:async';
import 'dart:convert';

import 'package:app/confirm_exit_dialog.dart';
import 'package:app/fieldwidget.dart';
import 'package:app/main.dart';
import 'package:app/scouting_tools/scouting_tool.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:snout_db/config/matcheventconfig.dart';
import 'package:snout_db/event/matchevent.dart';
import 'package:snout_db/event/pitscoutresult.dart';
import 'package:snout_db/event/robotmatchresults.dart';
import 'dart:math' as math;

import 'package:snout_db/snout_db.dart';

class MatchRecorderPage extends StatefulWidget {
  final int team;
  final Alliance teamAlliance;

  const MatchRecorderPage(
      {super.key, required this.team, required this.teamAlliance});

  @override
  State<MatchRecorderPage> createState() => _MatchRecorderPageState();
}

enum MatchMode { setup, playing, finished }

class _MatchRecorderPageState extends State<MatchRecorderPage> {
  MatchMode _mode = MatchMode.setup;
  List<MatchEvent> events = [];
  PitScoutResult postGameSurvey = {};
  int _time = 0;
  double mapRotation = 0;
  Timer? t;

  MatchEvent? get lastMoveEvent =>
      events.toList().lastWhereOrNull((event) => event.id == "robot_position");
  FieldPosition? get robotPosition => lastMoveEvent?.position;

  List<MatchEventConfig> get scoutingEvents =>
      context.read<EventDB>().db.config.matchscouting.events;

  @override
  void dispose() {
    t?.cancel();
    super.dispose();
  }

  Widget getEventButton(MatchEventConfig tool) {
    final fieldStyle = context.read<EventDB>().db.config.fieldStyle;

    //Disable the button if it is for teleop ONLY during the auto phase.
    final bool disabledForAuto =
        _time <= 17 && tool.mode == MatchSegment.teleop ? true : false;

    //Disable the button if it is for teleop ONLY during the auto phase.
    final bool disabledForTeleop =
        _time > 17 && tool.mode == MatchSegment.auto ? true : false;

    return Card(
      child: MaterialButton(
        onPressed: _mode == MatchMode.setup ||
                disabledForAuto ||
                disabledForTeleop ||
                lastMoveEvent == null ||
                _time - lastMoveEvent!.time > 4
            ? null
            : () {
                HapticFeedback.mediumImpact();
                setState(() {
                  if (_mode != MatchMode.setup && robotPosition != null) {
                    events.add(MatchEvent.fromEventConfig(
                        time: _time,
                        event: tool,
                        position: robotPosition!,
                        redNormalizedPosition:
                            widget.teamAlliance == Alliance.red
                                ? robotPosition!
                                : fieldStyle == FieldStyle.rotated
                                    ? robotPosition!.inverted
                                    : robotPosition!.mirrored));
                  }
                });
              },
        child: Text(tool.label),
      ),
    );
  }

  List<Widget> getTimeline() {
    return [
      const Center(
          child: Text(
              "Check to see the map is rotated correctly! Press 'start' when you hear the field buzzer and see the field lights. It is more important to know the location of each event rather than the position of the robot at all times. Event buttons will disable if no position has been recently input.")),
      const SizedBox(height: 32),
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
    //Allow slightly wide to be considered vertical for foldable devices or near-square devices
    final isHorizontal = MediaQuery.of(context).size.aspectRatio > 1.2;
    //used to normalize the field position
    final fieldStyle = context.watch<EventDB>().db.config.fieldStyle;

    if (_mode == MatchMode.finished) {
      return ConfirmExitDialog(
        child: Scaffold(
          appBar: AppBar(
            title: Text("Team ${widget.team}"),
            actions: [
              IconButton(
                  onPressed: () {
                    Navigator.pop(
                        context,
                        RobotMatchResults(
                            timeline: events, survey: postGameSurvey));
                  },
                  icon: const Icon(Icons.save)),
            ],
          ),
          body: ListView(
            shrinkWrap: true,
            children: [
              for (var item in context.watch<EventDB>()
                  .db
                  .config
                  .matchscouting
                  .postgame)
                Container(
                    padding: const EdgeInsets.all(12),
                    child: ScoutingToolWidget(
                      tool: item,
                      survey: postGameSurvey,
                    )),
            ],
          ),
        ),
      );
    }

    if (isHorizontal) {
      return ConfirmExitDialog(
        child: Scaffold(
          appBar: AppBar(
            title: Text("Team ${widget.team}"),
            actions: [statusAndToolBar()],
          ),
          body: Row(
            children: [
              SizedBox(
                width: 120 * 3,
                child: Column(
                  children: [
                    Expanded(
                      child: ListView(
                        reverse: true,
                        shrinkWrap: true,
                        children: getTimeline().reversed.toList(),
                      ),
                    ),
                    Wrap(
                      children: [
                        for (int i = 0; i < scoutingEvents.length; i++)
                          SizedBox(
                            height: 60,
                            width: 120, // -1 for some layout padding.
                            child: getEventButton(scoutingEvents[i]),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 600),
                  alignment: Alignment.bottomRight,
                  child: Transform.rotate(
                    angle: mapRotation,
                    child: FieldPositionSelector(
                      coverAlignment: _mode != MatchMode.setup ? null : widget.teamAlliance == Alliance.red ? 1 : -1,
                      teamNumber: widget.team,
                      alliance: widget.teamAlliance,
                      robotPosition: robotPosition,
                      onTap: (robotPosition) {
                        HapticFeedback.lightImpact();
                        setState(() {
                          for (final event in events.toList()) {
                            if (event.id == "robot_position") {
                              //Is position event
                              if (event.time == _time) {
                                //Event is the same time, overrwite
                                events.remove(event);
                              }
                            }
                          }
                          events.add(MatchEvent.robotPositionEvent(
                              time: _time,
                              position: robotPosition,
                              redNormalizedPosition:
                                  widget.teamAlliance == Alliance.red
                                      ? robotPosition
                                      : fieldStyle == FieldStyle.rotated
                                          ? robotPosition.inverted
                                          : robotPosition.mirrored));
                        });
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ConfirmExitDialog(
      child: Scaffold(
        appBar: AppBar(
          title: Text("Team ${widget.team}"),
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
            statusAndToolBar(),
            Container(
              width: 600,
              alignment: Alignment.bottomRight,
              child: Transform.rotate(
                angle: mapRotation,
                child: FieldPositionSelector(
                  teamNumber: widget.team,
                  coverAlignment: _mode != MatchMode.setup ? null : widget.teamAlliance == Alliance.red ? 1 : -1,
                  alliance: widget.teamAlliance,
                  robotPosition: robotPosition,
                  onTap: (robotPosition) {
                    HapticFeedback.lightImpact();
                    setState(() {
                      for (final event in events.toList()) {
                        if (event.id == "robot_position") {
                          //Is position event
                          if (event.time == _time) {
                            //Event is the same time, overrwite
                            events.remove(event);
                          }
                        }
                      }
                      events.add(MatchEvent.robotPositionEvent(
                          time: _time,
                          position: robotPosition,
                          redNormalizedPosition:
                              widget.teamAlliance == Alliance.red
                                  ? robotPosition
                                  : fieldStyle == FieldStyle.rotated
                                      ? robotPosition.inverted
                                      : robotPosition.mirrored));
                    });
                  },
                ),
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
          ],
        ),
      ),
    );
  }

  Widget statusAndToolBar() {
    Widget? robotPicture;
    final pictureData = context
        .watch<EventDB>()
        .db
        .pitscouting[widget.team.toString()]?['robot_picture'];
    if (pictureData != null) {
      robotPicture = SizedBox(
        height: scoutImageSize,
        child: Image.memory(
            Uint8List.fromList(base64Decode(pictureData).cast<int>())),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
              tooltip: "Rotate Map",
              onPressed: () {
                setState(() {
                  mapRotation += math.pi;
                });
              },
              icon: const Icon(Icons.rotate_right)),
          const SizedBox(width: 12),
          Text("Time: $_time"),
          const SizedBox(width: 12),
          Text(_mode == MatchMode.setup
              ? "Waiting"
              : _mode == MatchMode.playing
                  ? _time > 17
                      ? "teleop"
                      : "auto"
                  : ""),
          const SizedBox(width: 12),
          if (robotPicture == null) const Text("No Picture Available"),
          if (robotPicture != null)
            Center(
              child: FilledButton.tonal(
                  onPressed: () {
                    showDialog(
                        context: context,
                        builder: (bc) {
                          return AlertDialog(
                            content: robotPicture!,
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.pop(bc),
                                  child: const Text("Okay")),
                            ],
                          );
                        });
                  },
                  child: const Text("Robot Picture")),
            ),
          const SizedBox(width: 12),
          FilledButton.icon(
            icon: const Icon(Icons.arrow_forward),
            style: _mode == MatchMode.playing
                ? FilledButton.styleFrom(
                    backgroundColor: Colors.red, foregroundColor: Colors.white)
                : null,
            onPressed: lastMoveEvent == null ? null : handleNextSection,
            label: Text(_mode == MatchMode.setup
                ? "Start"
                : _mode == MatchMode.playing
                    ? "End"
                    : ""),
          ),
        ],
      ),
    );
  }

  void handleNextSection() {
    HapticFeedback.heavyImpact();
    if (_mode == MatchMode.playing) {
      //Stop timer
      t?.cancel();
      _mode = MatchMode.finished;
      //Scale auto times
      for (var event in events) {
        //Scale times to 15 seconds
        event.time = ((event.time / _time) * matchLength.inSeconds).round();
      }
      _time = matchLength.inSeconds;
    }
    if (_mode == MatchMode.setup) {
      _mode = MatchMode.playing;
      _time = 1; //Second 0 is reserved for pre-game events
      //Start timer
      t = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_mode != MatchMode.finished) {
          setState(() {
            _time++;
            if (_time == 16) {
              //Buzz the device for end of auto
              HapticFeedback.heavyImpact();
              Timer(const Duration(milliseconds: 500), () {
                HapticFeedback.heavyImpact();
              });
              Timer(const Duration(milliseconds: 1000), () {
                HapticFeedback.heavyImpact();
              });
            }
          });
        }
      });
    }
    setState(() {});
  }
}
