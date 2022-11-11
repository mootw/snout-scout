import 'dart:async';

import 'package:app/confirm_exit_dialog.dart';
import 'package:app/fieldwidget.dart';
import 'package:app/main.dart';
import 'package:app/scouting_tools/scouting_tool.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:snout_db/event/pitscoutresult.dart';
import 'package:snout_db/event/robotmatchresults.dart';
import 'dart:math' as math;

import 'package:snout_db/season/matchevent.dart';
import 'package:snout_db/snout_db.dart';

class MatchRecorderPage extends StatefulWidget {
  final int team;

  const MatchRecorderPage({required this.team, Key? key}) : super(key: key);

  @override
  State<MatchRecorderPage> createState() => _MatchRecorderPageState();
}

//TODO move this from the UI to snout_db
Duration matchLength = const Duration(minutes: 2, seconds: 31);
//0 seconds is reserved for events before the match starts like starting pos
//1 to 16 seconds are for auto (15 seconds)
//17; the delay between teleop and auto is ignored and treated as auto
//for scoring and scouting UI purposes. It is better that the scout records
//an auto event outside of auto than to miss the transition messing up the
//entire match recording
//18 to 153 are teleop
//because the time resolution is 1 second internally to snout-scout

enum MatchMode { setup, playing, finished }

class _MatchRecorderPageState extends State<MatchRecorderPage> {
  MatchMode _mode = MatchMode.setup;
  List<MatchEvent> events = [];
  PitScoutResult postGameSurvey = {};
  int _time = 0;
  double mapRotation = 0;
  Timer? t;

  MatchEvent? get lastMoveEvent => events.toList().lastWhereOrNull((event) => event.id == "robot_position");
  RobotPosition? get robotPosition => lastMoveEvent == null ? null : RobotPosition.fromMatchEvent(lastMoveEvent!);

  get scoutingEvents => _time <= 17
      ? Provider.of<SnoutScoutData>(context, listen: false)
          .season
          .matchscouting
          .auto
      : Provider.of<SnoutScoutData>(context, listen: false)
          .season
          .matchscouting
          .teleop;

  @override
  void dispose() {
    t?.cancel();
    super.dispose();
  }

  Widget getEventButton(MatchEvent tool) {
    return Card(
      child: MaterialButton(
        onPressed: lastMoveEvent == null || _time - lastMoveEvent!.time > 3 ? null : () {
          HapticFeedback.mediumImpact();
          setState(() {
            if (_mode != MatchMode.setup) {
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
      const Center(
          child: Text("Press 'start' when you hear the field buzzer. It is more important to know the location of each event rather than the position of the robot at all times. Event buttons will disable if no position has been recently input.")),
      const SizedBox(height: 32),
      const Center(
          child: SizedBox(height: 32, child: Text("Start of Timeline"))),
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
              for (var item
                  in Provider.of<SnoutScoutData>(context, listen: false)
                      .season
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
                width: 130 * 3,
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
                            width: 130, // -1 for some layout padding.
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
                              x: robotPosition.x,
                              y: robotPosition.y));
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
                          time: _time, x: robotPosition.x, y: robotPosition.y));
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
              icon: Icon(Icons.rotate_right)),
          const SizedBox(width: 12),
          Text("Time: $_time"),
          const SizedBox(width: 12),
          Text(
              "${_mode == MatchMode.setup ? "Waiting" : _mode == MatchMode.playing ? "${_time > 17 ? "teleop" : "auto"}" : ""}"),
          const SizedBox(width: 12),
          FilledButton.icon(
            icon: const Icon(Icons.arrow_forward),
            onPressed: handleNextSection,
            label: Text(
                "${_mode == MatchMode.setup ? "Start" : _mode == MatchMode.playing ? "End" : ""}"),
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
