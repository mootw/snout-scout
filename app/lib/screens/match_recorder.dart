import 'dart:async';

import 'package:app/data/season_config.dart';
import 'package:app/main.dart';
import 'package:flutter/material.dart';

class MatchRecorderPage extends StatefulWidget {
  const MatchRecorderPage({Key? key}) : super(key: key);

  @override
  State<MatchRecorderPage> createState() => _MatchRecorderPageState();
}

//Match duration = 150
//The delay between teleop and auto are ignored
//because the time resolution is 1 second.

enum MatchMode { PRE_GAME, AUTO, TELEOP, FINISHED }

class TimelineEvent {
  num time;
  ScoutingToolData data;

  TimelineEvent(this.time, this.data);
}

class _MatchRecorderPageState extends State<MatchRecorderPage> {
  MatchMode _mode = MatchMode.PRE_GAME;

  List<TimelineEvent> events = [];

  int _time = 0;

  @override
  void initState() {
    super.initState();
  }

  Widget getEventButton(ScoutingToolData tool) {
    return Card(
      child: MaterialButton(
        onPressed: () {
          setState(() {
            events.add(TimelineEvent(_time, tool));
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
        Row(
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
            )
          ],
        ),
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    var scouting_events = snoutData.config!.matchScouting.auto;

    return Scaffold(
      appBar: AppBar(
        title: Text(
            "Team 1234 - ${_mode == MatchMode.PRE_GAME ? "Waiting to start" : _mode == MatchMode.AUTO ? "Auto" : _mode == MatchMode.TELEOP ? "Teleop" : _mode == MatchMode.FINISHED ? "Finished" : "Unknown State"} - ${_time}"),
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
          Container(
            color: Colors.black,
            padding: EdgeInsets.only(left: 8, right: 8),
            width: double.infinity,
            child: Image.network("${snoutData.serverURL}/field_map.png",
                height: 220),
          ),
          SizedBox(height: 16),
          Wrap(
            children: [
              for (int i = 0; i < scouting_events.length; i++)
                SizedBox(
                  height: 80,
                  width: MediaQuery.of(context).size.width / 3,
                  child: getEventButton(scouting_events[i]),
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
                      if (_mode == MatchMode.TELEOP) {
                        //TODO finish the recording.
                      }
                      if (_mode == MatchMode.AUTO) {
                        _mode = MatchMode.TELEOP;
                      }
                      if (_mode == MatchMode.PRE_GAME) {
                        _mode = MatchMode.AUTO;
                        //Start timer
                        Timer.periodic(Duration(seconds: 1), (timer) {
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
                        "Next segment: ${_mode == MatchMode.PRE_GAME ? "Start Recording" : _mode == MatchMode.AUTO ? "Teleop" : _mode == MatchMode.TELEOP ? "Finish Recordig" : "Done"}"),
                  ),
                ]),
          ),
        ],
      ),
    );
  }
}


/*
MaterialButton(
                  child: Text("Event Button Name"),
                  onPressed: () {
                    
                }),
                MaterialButton(
                  child: Text("Event Button Name"),
                  onPressed: () {
                    
                }),
                MaterialButton(
                  child: Text("Event Button Name"),
                  onPressed: () {
                    
                }),
                MaterialButton(
                  child: Text("Event Button Name"),
                  onPressed: () {
                    
                }),
                MaterialButton(
                  child: Text("Event Button Name"),
                  onPressed: () {
                    
                }),
                MaterialButton(
                  child: Text("Event Button Name"),
                  onPressed: () {
                    
                }),
                MaterialButton(
                  child: Text("Event Button Name"),
                  onPressed: () {
                    
                }),
*/