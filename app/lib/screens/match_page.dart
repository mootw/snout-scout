import 'dart:convert';

import 'package:app/datasheet.dart';
import 'package:app/edit_lock.dart';
import 'package:app/fieldwidget.dart';
import 'package:app/helpers.dart';
import 'package:app/main.dart';
import 'package:app/screens/analysis/match_preview.dart';
import 'package:app/screens/edit_match_results.dart';
import 'package:app/screens/match_recorder.dart';
import 'package:app/screens/view_team_page.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:snout_db/config/surveyitem.dart';
import 'package:snout_db/event/match.dart';
import 'package:snout_db/event/robotmatchresults.dart';
import 'package:snout_db/patch.dart';
import 'package:snout_db/snout_db.dart';
import 'package:url_launcher/url_launcher_string.dart';

class MatchPage extends StatefulWidget {
  const MatchPage({required this.matchid, Key? key}) : super(key: key);

  final String matchid;

  @override
  State<MatchPage> createState() => _MatchPageState();
}

class _MatchPageState extends State<MatchPage> {
  final TextEditingController _textController = TextEditingController();
  Alliance alliance = Alliance.blue;

  @override
  Widget build(BuildContext context) {
    final snoutData = context.watch<EventDB>();
    FRCMatch match = snoutData.db.matches[widget.matchid]!;
    return Scaffold(
      appBar: AppBar(
        title: Text(match.description),
        actions: [
          //If there is a TBA event ID we will add a button to view the match id
          //since we will assume that all of the matches (or at least most)
          //have been imported to match the tba id format
          if (snoutData.db.config.tbaEventId != null)
            FilledButton.tonal(
              child: const Text("TBA"),
              onPressed: () => launchUrlString(
                  "https://www.thebluealliance.com/match/${widget.matchid}"),
            ),
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
                    time: DateTime.now(),
                    path: ['matches', widget.matchid, 'results'],
                    data: jsonEncode(result));

                await snoutData.addPatch(patch);
              }
            },
          ),
        ],
      ),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          Wrap(
            children: [
              const SizedBox(width: 16),
              FilledButton(
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (builder) => AnalysisMatchPreview(
                                red: match.red, blue: match.blue)));
                  },
                  child: const Text("Match Preview"))
            ],
          ),
          const SizedBox(height: 8),
          DataSheet(
            title: 'Per Team Performance',
            //Data is a list of rows and columns
            columns: [
              DataItem.fromText("Team"),
              DataItem.fromText("Timeline"),
              for (final item in snoutData.db.config.matchscouting.events)
                DataItem.fromText(item.label),
              for (final item in snoutData.db.config.matchscouting.events)
                DataItem.fromText('auto\n${item.label}'),
              for (final item in snoutData.db.config.matchscouting.postgame)
                DataItem.fromText(item.label),
            ],
            rows: [
              for (final team in <int>{
                ...match.red,
                ...match.blue,
                //Also include all of the surrogate robots
                ...match.robot.keys.map((e) => int.tryParse(e)).whereNotNull()
              })
                [
                  DataItem(
                      displayValue: TextButton(
                        child: Text(
                            team.toString() +
                                (match.hasTeam(team) == false
                                    ? " [surrogate]"
                                    : ""),
                            style: TextStyle(
                                color: match.hasTeam(team) == false
                                    ? null
                                    : getAllianceColor(
                                        match.getAllianceOf(team)))),
                        onPressed: () {
                          //Open this teams scouting page
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    TeamViewPage(teamNumber: team)),
                          );
                        },
                      ),
                      exportValue: team.toString(),
                      sortingValue: team),
                  DataItem(
                      displayValue: TextButton(
                        child: const Text("Record"),
                        onPressed: () async {
                          RobotMatchResults? result =
                              await navigateWithEditLock(
                                  context,
                                  "match:${match.description}:$team:timeline",
                                  () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                MatchRecorderPage(
                                                    team: team,
                                                    teamAlliance: match
                                                        .getAllianceOf(team))),
                                      ));

                          if (result != null) {
                            Patch patch = Patch(
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
                      ),
                      exportValue: "Record",
                      sortingValue: "Record"),
                  for (final item in snoutData.db.config.matchscouting.events)
                    DataItem.fromNumber(match.robot[team.toString()]?.timeline
                        .where((event) => event.id == item.id)
                        .length
                        .toDouble()),
                    for (final item in snoutData.db.config.matchscouting.events)
                    DataItem.fromNumber(match.robot[team.toString()]?.timeline
                        .where((event) => event.isInAuto && event.id == item.id)
                        .length
                        .toDouble()),
                    
                  for (final item in snoutData.db.config.matchscouting.postgame
                      .where(
                          (element) => element.type != SurveyItemType.picture))
                    DataItem.fromText(match
                        .robot[team.toString()]?.survey[item.id]
                        ?.toString()),
                ],
            ],
          ),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            Flexible(
              child: TextField(
                decoration: const InputDecoration(
                  // border: OutlineInputBorder(),
                  hintText: 'Wrong team?',
                ),
                autocorrect: false,
                keyboardType: TextInputType.number,
                controller: _textController,
              ),
            ),
            Flexible(
              child: DropdownButton<Alliance>(
                value: alliance,
                onChanged: (Alliance? value) {
                  setState(() {
                    alliance = value!;
                  });
                },
                items: [Alliance.blue, Alliance.red]
                    .map<DropdownMenuItem<Alliance>>((Alliance value) {
                  return DropdownMenuItem<Alliance>(
                    value: value,
                    child: Text(value.toString(),
                        style: TextStyle(color: getAllianceColor(value))),
                  );
                }).toList(),
              ),
            ),
            Flexible(
              child: TextButton(
                  onPressed: () async {
                    //TODO this isnt very safe :(
                    int team = int.parse(_textController.text);
                    RobotMatchResults? result = await navigateWithEditLock(
                        context,
                        "match:${match.description}:$team:timeline",
                        () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => MatchRecorderPage(
                                      team: team, teamAlliance: alliance)),
                            ));
                    if (result != null) {
                      Patch patch = Patch(
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
                  child: const Text(
                    "Record\nSubstitution",
                    textAlign: TextAlign.center,
                  )),
            ),
          ]),
          const SizedBox(height: 32),
          FieldTimelineViewer(match: match),
          ListTile(
            title: const Text("Scheduled Time"),
            subtitle: Text(DateFormat.jm()
                .add_yMd()
                .format(match.scheduledTime.toLocal())),
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
    );
  }
}
