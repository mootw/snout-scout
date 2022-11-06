import 'dart:convert';

import 'package:app/edit_lock.dart';
import 'package:app/main.dart';
import 'package:app/map_viewer.dart';
import 'package:app/screens/edit_match_results.dart';
import 'package:app/screens/match_recorder.dart';
import 'package:flutter/material.dart';
import 'package:snout_db/event/match.dart';
import 'package:snout_db/patch.dart';
import 'package:snout_db/season/matchevent.dart';

class MatchPage extends StatefulWidget {
  const MatchPage({required this.match, Key? key}) : super(key: key);

  final FRCMatch match;

  @override
  State<MatchPage> createState() => _MatchPageState();
}

class _MatchPageState extends State<MatchPage> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
        length: 7,
        child: Scaffold(
          appBar: AppBar(
            bottom: TabBar(
              isScrollable: true,
              tabs: [
                Tab(icon: Icon(Icons.videogame_asset)),
                Tab(
                    child: Text("${widget.match.red[0]}",
                        style: TextStyle(color: Colors.redAccent))),
                Tab(
                    child: Text("${widget.match.red[1]}",
                        style: TextStyle(color: Colors.redAccent))),
                Tab(
                    child: Text("${widget.match.red[2]}",
                        style: TextStyle(color: Colors.redAccent))),
                Tab(
                    child: Text("${widget.match.blue[0]}",
                        style: TextStyle(color: Colors.blueAccent))),
                Tab(
                    child: Text("${widget.match.blue[1]}",
                        style: TextStyle(color: Colors.blueAccent))),
                Tab(
                    child: Text("${widget.match.blue[2]}",
                        style: TextStyle(color: Colors.blueAccent))),
              ],
            ),
            title: Text("Match ${widget.match.description}"),
          ),
          body: TabBarView(children: [
            _buildMatchView(widget.match, null),
            _buildMatchView(widget.match, widget.match.red[0]),
            _buildMatchView(widget.match, widget.match.red[1]),
            _buildMatchView(widget.match, widget.match.red[2]),
            _buildMatchView(widget.match, widget.match.blue[0]),
            _buildMatchView(widget.match, widget.match.blue[1]),
            _buildMatchView(widget.match, widget.match.blue[2]),
          ]),
        ));
  }

  Widget _buildMatchView(FRCMatch data, int? teamNumber) {
    if (teamNumber == null) {
      return Column(
        children: [
          SizedBox(
            height: 50,
            child: Center(
              child: ElevatedButton(
                child: data.results == null
                    ? Text("Add Results")
                    : Text("Edit results"),
                onPressed: () async {
                  var result = await navigateWithEditLock(
                      context,
                      "match:${data.id}:results",
                      () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditMatchResults(
                                match: data, config: snoutData.season!),
                          )));

                  if (result == true) {
                    setState(() {});
                  }
                },
              ),
            ),
          ),
          if (data.results != null)
            SizedBox(
              width: 200,
              child: Table(
                children: [
                  TableRow(children: [
                    Text(""),
                    Text("Red"),
                    Text("Blue"),
                  ]),
                  for (final type in snoutData.season!.matchscouting.scoring)
                    TableRow(children: [
                      Text(type),
                      Text(data.results!.red[type].toString()),
                      Text(data.results!.blue[type].toString()),
                    ]),
                ],
              ),
            ),

          Text("Display a 'video-like' overview of the map, starting with the robots start positions and includes all events through the match"),

          FieldMapViewer(
            events: [
              for (var timeline in data.timelines.keys)
                ...?data.timelines[timeline],
            ],
            onTap: (position) {},
          ),
          Text("Breakdown of the match including all teams. Metrics where applicable"),
        ],
      );
    }

    List<MatchEvent>? timeline = data.timelines[teamNumber.toString()];

    return Column(
      children: [
        SizedBox(
          height: 50,
          child: Center(
            child: ElevatedButton(
              child: timeline == null
                  ? Text("Record Match")
                  : Text("Edit Timeline"),
              onPressed: () async {
                List<MatchEvent>? result = await navigateWithEditLock(
                    context,
                    "match:${data.id}:$teamNumber:timeline",
                    () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  MatchRecorderPage(title: "Team $teamNumber")),
                        ));

                if (result != null) {
                  //TODO save data to the server

                  Patch patch = Patch(
                      user: "anon",
                      time: DateTime.now(),
                      path: [
                        'events',
                        snoutData.selectedEventID!,
                        'matches',
                        //Index of the match to modify. This could cause issues if
                        //the index of the match changes inbetween this database
                        //being updated and not. Ideally matches should have a unique key
                        //like their scheduled date to uniquely identify them.
                        snoutData.currentEvent.matches
                            .indexOf(widget.match)
                            .toString(),
                        'timelines',
                        teamNumber.toString()
                      ],
                      data: jsonEncode(result));

                  await snoutData.addPatch(patch);
                  setState(() {});
                }
              },
            ),
          ),
        ),

        Text("Breakdown of the match via this team's specific performance"),
      ],
    );
  }
}
