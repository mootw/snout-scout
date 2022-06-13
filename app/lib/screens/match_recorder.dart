import 'dart:async';

import 'package:app/data/matches.dart';
import 'package:app/data/season_config.dart';
import 'package:app/main.dart';
import 'package:app/map_viewer.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

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



class TimelineEvent {

  int time;
  ScoutingToolData data;

  Map<String, dynamic> toJson() => {
    "time": time,
    "data": data.toJson(),
  };

  TimelineEvent({required this.time, required this.data});
}

//Number between 0 and 1 on both axis
//Positive X is towards the opposing alliance.
//Positive Y is along the alliance wall
//Map is the field boundry.
// (0, 0) is the corner to the left and closest
// to the scoring table.
class RobotPosition {
  double x;
  double y;

  RobotPosition(this.x, this.y);
}

class _MatchRecorderPageState extends State<MatchRecorderPage> {
  MatchMode _mode = MatchMode.PRE_GAME;

  List<TimelineEvent> events = [];

  RobotPosition? lastRobotPosition;


  //Time = 0 is reserved for pre-game
  //
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

  Widget getEventButton(ScoutingToolData tool) {
    return Card(
      child: MaterialButton(
        onPressed: () {
          setState(() {
            if(_mode != MatchMode.PRE_GAME) {
              events.add(TimelineEvent(time: _time, data: tool));
            }
          });
        },
        child: Text(tool.label),
      ),
    );
  }

  List<Widget> getTimeline() {
    return [
      Container(
          width: double.infinity,
          height: 50,
          alignment: Alignment.center,
          child: const Text("Start of timeline")),
      for (final item in events.toList()) ...[
        const Divider(height: 0),
        Padding(
          padding: const EdgeInsets.only(left: 12, right: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(item.time.round().toString()),
              Text(item.data.label),
              IconButton(
                color: Theme.of(context).errorColor,
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
    
    final scoutingEvents = _mode == MatchMode.AUTO || _mode == MatchMode.PRE_GAME ? snoutData.config!.matchScouting.auto : _mode == MatchMode.TELEOP ? snoutData.config!.matchScouting.teleop : [];

    return Scaffold(
      appBar: AppBar(
        title: Text(
            "${widget.title} - ${_mode == MatchMode.PRE_GAME ? "Waiting to start" : _mode == MatchMode.AUTO ? "Auto" : _mode == MatchMode.TELEOP ? "Teleop" : _mode == MatchMode.FINISHED ? "Finished" : "Unknown State"} - ${_time}"),
        actions: [
          IconButton(onPressed: () {
            setState(() {
              mapRotation += math.pi;
            });
          }, icon: Icon(Icons.rotate_right)),
        ],
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
            constraints: BoxConstraints(maxHeight: 300),
            padding: EdgeInsets.only(left: 8, right: 8),
            child: Transform.rotate(
              angle: mapRotation,
              child: FieldMapViewer(
                robotPosition: lastRobotPosition,
                onTap: (robotPosition) {
                  print("${robotPosition.x} ${robotPosition.y}");
                  lastRobotPosition = robotPosition;
                  setState(() {
                    for(final event in events.toList()) {
                      if(event.data.type == "robot_position") {
                        //Is position event
                        if(event.time == _time) {
                          //Event is the same time, overrwite
                          events.remove(event);
                        }
                      }
                    }
                    events.add(TimelineEvent(time: _time, data: ScoutingToolData.fromPosition(robotPosition.x, robotPosition.y)));
                  });
                },),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            children: [
              for (int i = 0; i < scoutingEvents.length; i++)
                SizedBox(
                  height: 80,
                  width: MediaQuery.of(context).size.width / 3,
                  child: getEventButton(scoutingEvents[i]),
                ),
            ],
          ),
          Container(
            margin: const EdgeInsets.all(16),
            // color: Colors.amber,
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(
                          content: Text("Long press to move to next section")));
                    },
                    onLongPress: () {
                        print(_mode);
                      if(_mode == MatchMode.FINISHED) {
                        Navigator.pop(context, events);
                      }
                      if (_mode == MatchMode.TELEOP) {
                        //Stop timer
                        t?.cancel();
                        _mode = MatchMode.FINISHED;
                        for(var event in events) {
                          //Scale times between 15 seconds and 150 seconds
                          if(event.time > 15) {
                            num offsetTime = event.time - 15;
                            event.time = (15 + ((offsetTime/(_time - 15)) * 135)).round();
                          }
                        }

                        _time = 150;
                      }
                      if (_mode == MatchMode.AUTO) {
                        _mode = MatchMode.TELEOP;
                        //Scale auto times
                        for(var event in events) {
                          //Scale times to 15 seconds
                          event.time = ((event.time/_time) * 15).round();
                        }
                        //Set time to 15 if auto was recorded faster than real time.
                        if(_time < 15) {
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
                        "Next segment: ${_mode == MatchMode.PRE_GAME ? "Start Recording" : _mode == MatchMode.AUTO ? "Teleop" : _mode == MatchMode.TELEOP ? "Finish Recordig" : "Save"}"),
                  ),
                ]),
          ),
        ],
      ),
    );
  }
}