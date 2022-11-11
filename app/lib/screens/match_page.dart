import 'dart:convert';

import 'package:app/edit_lock.dart';
import 'package:app/fieldwidget.dart';
import 'package:app/main.dart';
import 'package:app/screens/edit_match_results.dart';
import 'package:app/screens/match_recorder.dart';
import 'package:app/screens/view_team_page.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:snout_db/event/match.dart';
import 'package:snout_db/event/robotmatchresults.dart';
import 'package:snout_db/patch.dart';

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
                      child: GestureDetector(
                          child: Text("${match.red[0]}",
                              style: TextStyle(color: Colors.redAccent)),
                          onLongPress: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      TeamViewPage(teamNumber: match.red[0])),
                            );
                          })),
                  Tab(
                      child: GestureDetector(
                          child: Text("${match.red[1]}",
                              style: TextStyle(color: Colors.redAccent)),
                          onLongPress: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      TeamViewPage(teamNumber: match.red[1])),
                            );
                          })),
                  Tab(
                      child: GestureDetector(
                          child: Text("${match.red[2]}",
                              style: TextStyle(color: Colors.redAccent)),
                          onLongPress: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      TeamViewPage(teamNumber: match.red[2])),
                            );
                          })),
                  Tab(
                      child: GestureDetector(
                          child: Text("${match.blue[0]}",
                              style: TextStyle(color: Colors.blueAccent)),
                          onLongPress: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      TeamViewPage(teamNumber: match.blue[0])),
                            );
                          })),
                  Tab(
                      child: GestureDetector(
                          child: Text("${match.blue[1]}",
                              style: TextStyle(color: Colors.blueAccent)),
                          onLongPress: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      TeamViewPage(teamNumber: match.blue[1])),
                            );
                          })),
                  Tab(
                      child: GestureDetector(
                          child: Text("${match.blue[2]}",
                              style: TextStyle(color: Colors.blueAccent)),
                          onLongPress: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      TeamViewPage(teamNumber: match.blue[2])),
                            );
                          })),
                ],
              ),
              title: Text(match.description),
              actions: [
                Text(DefaultTabController.of(context)?.index.toString() ?? ""),
                TextButton(
                  child: match.results == null
                      ? Text("Add Results")
                      : Text("Edit Results"),
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
          FieldTimelineViewer(match: data),
          Text(
              "Breakdown of the match including all teams. Metrics where applicable"),
        ],
      );
    }

    RobotMatchResults? timeline = data.robot[teamNumber.toString()];
    final survey = data.robot[teamNumber.toString()]?.survey;

    return ListView(
      children: [
        Center(
          child: FilledButton.tonal(
            child:
                timeline == null ? Text("Record Match") : Text("Edit Timeline"),
            onPressed: () async {
              RobotMatchResults? result = await navigateWithEditLock(
                  context,
                  "match:${data.id}:$teamNumber:timeline",
                  () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                MatchRecorderPage(team: teamNumber)),
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
                      'robot',
                      teamNumber.toString()
                    ],
                    data: jsonEncode(result));

                await snoutData.addPatch(patch);
                setState(() {});
              }
            },
          ),
        ),
        if (survey != null)
          Text("Post Match Survey",
              style: Theme.of(context).textTheme.titleMedium),
        if (survey != null)
          Column(
            children: [
              for (final item in snoutData.season.matchscouting.postgame)
                ScoutingResult(item: item, survey: survey),
            ],
          ),
        Text("Breakdown of the match via this team's specific performance"),
      ],
    );
  }
}
