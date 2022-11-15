import 'dart:convert';

import 'package:app/edit_lock.dart';
import 'package:app/fieldwidget.dart';
import 'package:app/main.dart';
import 'package:app/screens/datapage.dart';
import 'package:app/screens/edit_match_results.dart';
import 'package:app/screens/match_recorder.dart';
import 'package:app/screens/view_team_page.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:snout_db/config/surveyitem.dart';
import 'package:snout_db/event/match.dart';
import 'package:snout_db/event/robotmatchresults.dart';
import 'package:snout_db/patch.dart';
import 'package:snout_db/snout_db.dart';

class MatchPage extends StatefulWidget {
  const MatchPage({required this.matchid, Key? key}) : super(key: key);

  final String matchid;

  @override
  State<MatchPage> createState() => _MatchPageState();
}

class _MatchPageState extends State<MatchPage> {
  @override
  Widget build(BuildContext context) {
    return Consumer<SnoutScoutData>(builder: (context, snoutData, child) {
      FRCMatch match = snoutData.db.matches[widget.matchid]!;

      return DefaultTabController(
          length: 7,
          child: Scaffold(
            appBar: AppBar(
              title: Text(match.description),
              actions: [
                Text(DefaultTabController.of(context)?.index.toString() ?? ""),
                TextButton(
                  child: match.results == null
                      ? const Text("Add Results")
                      : const Text("Edit Results"),
                  onPressed: () async {
                    var result = await navigateWithEditLock(
                        context,
                        "match:${match.description}:results",
                        () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditMatchResults(
                                  results: match.results,
                                  config: snoutData.db.config),
                            )));

                    if (result != null) {
                      Patch patch = Patch(
                          user: "anon",
                          time: DateTime.now(),
                          path: ['matches', widget.matchid, 'results'],
                          data: jsonEncode(result));

                      await snoutData.addPatch(patch);
                    }
                  },
                )
              ],
            ),
            body: ListView(
        children: [

          ScrollConfiguration(
              behavior: MouseInteractableScrollBehavior(),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(columns: [
                  const DataColumn(label: Text("Team")),
                  const DataColumn(label: Text("Timeline")),
                  for (final item in snoutData.db.config.matchscouting.events)
                    DataColumn(label: Text(item.label)),
                  for (final item in snoutData.db.config.matchscouting.postgame)
                    DataColumn(label: Text(item.label)),
                  // for(final item in snoutData.db.config.matchscouting.events)
                ], rows: [
                  for (final team in [...match.red, ...match.blue])
                    DataRow(cells: [
                      DataCell(TextButton(
                        child: Text(team.toString(), style: TextStyle(color: match.getAllianceOf(team) == Alliance.red ? Colors.red : Colors.blue)),
                        onPressed: () {
                          //Open this teams scouting page
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    TeamViewPage(teamNumber: team)),
                          );
                        },
                      )),

                      DataCell(FilledButton.tonal(
            child: match.robot[team.toString()] == null
                ? const Text("Record")
                : const Text("Re-record"),
            onPressed: () async {
              RobotMatchResults? result = await navigateWithEditLock(
                  context,
                  "match:${match.description}:$team:timeline",
                  () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => MatchRecorderPage(
                                team: team,
                                teamAlliance: match.getAllianceOf(team))),
                      ));

              if (result != null) {
                Patch patch = Patch(
                    user: "anon",
                    time: DateTime.now(),
                    path: [
                      'matches',
                      widget.matchid,
                      'robot',
                      team.toString()
                    ],
                    data: jsonEncode(result));
                await snoutData.addPatch(patch);
              }
            },
          )),

                      for (final item
                          in snoutData.db.config.matchscouting.events)
                            DataCell(Text(numDisplay(match
                                .robot[team.toString()]?.timeline
                                .where((event) => event.id == item.id)
                                .length
                                .toDouble()))),
                      for (final item in snoutData
                              .db.config.matchscouting.postgame
                              .where((element) => element.type != SurveyItemType.picture))
                            DataCell(Text(match
                                    .robot[team.toString()]
                                    ?.survey[item.id]
                                    ?.toString() ??
                                "No Data")),
                    ]),
                ]),
              )),
          const SizedBox(height: 16),
          FieldTimelineViewer(match: match),
          ListTile(
            title: const Text("Scheduled Time"),
            subtitle: Text(
                DateFormat.jm().add_yMd().format(match.scheduledTime.toLocal())),
          ),
          if (match.results != null)
            ListTile(
              title: const Text("Actual Time"),
              subtitle: Text(DateFormat.jm()
                  .add_yMd()
                  .format(match.results!.time.toLocal())),
            ),
          if (match.results != null)
            Align(
              alignment: Alignment.center,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text("Results")),
                  DataColumn(label: Text("Red")),
                  DataColumn(label: Text("Blue")),
                ],
                rows: [
                  for (final type in snoutData.db.config.matchscouting.scoring)
                    DataRow(cells: [
                      DataCell(Text(type)),
                      DataCell(Text(match.results!.red[type].toString())),
                      DataCell(Text(match.results!.blue[type].toString())),
                    ]),
                ],
              ),
            ),
        ],
      ),
          ));
    });
  }

}
