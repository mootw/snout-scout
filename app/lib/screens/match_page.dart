import 'dart:convert';

import 'package:app/edit_lock.dart';
import 'package:app/main.dart';
import 'package:app/screens/edit_match_results.dart';
import 'package:app/screens/match_recorder.dart';
import 'package:app/screens/view_team_page.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:snout_db/event/match.dart';
import 'package:snout_db/patch.dart';
import 'package:snout_db/season/matchevent.dart';

class MatchPage extends StatefulWidget {
  const MatchPage({required this.matchid, Key? key}) : super(key: key);

  final int matchid;

  @override
  State<MatchPage> createState() => _MatchPageState();
}

class _MatchPageState extends State<MatchPage> {
  @override
  Widget build(BuildContext context) {
    return Consumer<SnoutScoutData>(builder: (context, snoutData, child) {
      FRCMatch match = snoutData.currentEvent.matches[widget.matchid];

      return DefaultTabController(
          length: 7,
          child: Scaffold(
            appBar: AppBar(
              bottom: TabBar(
                isScrollable: true,
                tabs: [
                  Tab(icon: Icon(Icons.videogame_asset)),
                  Tab(
                      child: Text("${match.red[0]}",
                          style: TextStyle(color: Colors.redAccent))),
                  Tab(
                      child: Text("${match.red[1]}",
                          style: TextStyle(color: Colors.redAccent))),
                  Tab(
                      child: Text("${match.red[2]}",
                          style: TextStyle(color: Colors.redAccent))),
                  Tab(
                      child: Text("${match.blue[0]}",
                          style: TextStyle(color: Colors.blueAccent))),
                  Tab(
                      child: Text("${match.blue[1]}",
                          style: TextStyle(color: Colors.blueAccent))),
                  Tab(
                      child: Text("${match.blue[2]}",
                          style: TextStyle(color: Colors.blueAccent))),
                ],
              ),
              title: Text(match.description),
              actions: [
                TextButton(
                  child: match.results == null
                      ? Text("Add Results")
                      : Text("Edit results"),
                  onPressed: () async {
                    var result = await navigateWithEditLock(
                        context,
                        "match:${match.id}:results",
                        () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditMatchResults(
                                  match: match, config: snoutData.season),
                            )));

                    if (result == true) {
                      setState(() {});
                    }
                  },
                )
              ],
            ),
            body: TabBarView(children: [
              _buildMatchView(snoutData, match, null),
              _buildMatchView(snoutData, match, match.red[0]),
              _buildMatchView(snoutData, match, match.red[1]),
              _buildMatchView(snoutData, match, match.red[2]),
              _buildMatchView(snoutData, match, match.blue[0]),
              _buildMatchView(snoutData, match, match.blue[1]),
              _buildMatchView(snoutData, match, match.blue[2]),
            ]),
          ));
    });
  }

  Widget _buildMatchView(
      SnoutScoutData snoutData, FRCMatch data, int? teamNumber) {
    if (teamNumber == null) {
      return ListView(
        children: [
          ListTile(
            title: Text("Scheduled Time"),
            subtitle: Text(
                DateFormat.jm().add_yMd().format(data.scheduledTime.toLocal())),
          ),
          if (data.results != null)
            ListTile(
              title: Text("Actual Time"),
              subtitle: Text(DateFormat.jm()
                  .add_yMd()
                  .format(data.results!.time.toLocal())),
            ),
          if (data.results != null)
            Align(
              alignment: Alignment.center,
              child: DataTable(
                columns: [
                  DataColumn(label: Text("Results")),
                  DataColumn(label: Text("Red")),
                  DataColumn(label: Text("Blue")),
                ],
                rows: [
                  for (final type in snoutData.season.matchscouting.scoring)
                    DataRow(cells: [
                      DataCell(Text(type)),
                      DataCell(Text(data.results!.red[type].toString())),
                      DataCell(Text(data.results!.blue[type].toString())),
                    ]),
                ],
              ),
            ),
          Text(
              "Display a 'video-like' overview of the map, starting with the robots start positions and includes all events through the match"),
          Text(
              "Breakdown of the match including all teams. Metrics where applicable"),
        ],
      );
    }

    List<MatchEvent>? timeline = data.timelines[teamNumber.toString()];

    return Column(
      children: [
        FilledButton.tonal(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => TeamViewPage(teamNumber: teamNumber)),
              );
            },
            child: Text("Scout $teamNumber")),
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
                        snoutData.selectedEventID,
                        'matches',
                        //Index of the match to modify. This could cause issues if
                        //the index of the match changes inbetween this database
                        //being updated and not. Ideally matches should have a unique key
                        //like their scheduled date to uniquely identify them.
                        snoutData.currentEvent.matches.indexOf(data).toString(),
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
