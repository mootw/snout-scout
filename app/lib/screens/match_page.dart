import 'dart:convert';

import 'package:app/datasheet.dart';
import 'package:app/edit_lock.dart';
import 'package:app/eventdb_state.dart';
import 'package:app/fieldwidget.dart';
import 'package:app/helpers.dart';
import 'package:app/screens/analysis/match_preview.dart';
import 'package:app/screens/edit_match_results.dart';
import 'package:app/screens/match_recorder.dart';
import 'package:app/screens/match_recorder_assistant.dart';
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
  const MatchPage({super.key, required this.matchid});

  final String matchid;

  @override
  State<MatchPage> createState() => _MatchPageState();
}

class _MatchPageState extends State<MatchPage> {

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
              final result = await navigateWithEditLock(
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
                            builder: (builder) => MatchRecorderAssistantPage(
                                matchid: widget.matchid)));
                  },
                  child: const Text("Scout This Match")),
              const SizedBox(width: 16),
              FilledButton.tonal(
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (builder) => AnalysisMatchPreview(
                                red: match.red, blue: match.blue)));
                  },
                  child: const Text("Match Preview")),
            ],
          ),
          const SizedBox(height: 8),
          DataSheet(
            title: 'Per Team Performance',
            //Data is a list of rows and columns
            columns: [
              DataItem.fromText("Team"),
              for (final item in snoutData.db.config.matchscouting.processes)
                DataItem.fromText(item.label),
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
                                    ? getAllianceColor(match.robot[team.toString()]!.alliance)
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
                  for (final item
                      in snoutData.db.config.matchscouting.processes)
                    DataItem.fromNumber(snoutData.db.runMatchResultsProcess(
                        item, match.robot[team.toString()], team)),
                  for (final item in snoutData.db.config.matchscouting.postgame
                      .where(
                          (element) => element.type != SurveyItemType.picture))
                    DataItem.fromText(match
                        .robot[team.toString()]?.survey[item.id]
                        ?.toString()),
                ],
            ],
          ),
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
          //Heatmaps for this specific match
          Wrap(
            spacing: 12,
            alignment: WrapAlignment.center,
            children: [
              SizedBox(
                width: 360,
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    Text("Autos",
                        style: Theme.of(context).textTheme.titleMedium),
                    FieldPaths(
                      useRedNormalized: false,
                      paths: [
                        for (final robot in match.robot.values)
                          robot.timelineInterpolated
                              .where((element) => element.isInAuto)
                              .toList()
                      ],
                    ),
                  ],
                ),
              ),
              for (final eventType in snoutData.db.config.matchscouting.events)
                SizedBox(
                  width: 360,
                  child: Column(children: [
                    const SizedBox(height: 16),
                    Text(eventType.label,
                        style: Theme.of(context).textTheme.titleMedium),
                    FieldHeatMap(
                        useRedNormalized: false,
                        events: match.robot.values.fold(
                            [],
                            (previousValue, element) => [
                                  ...previousValue,
                                  ...element.timeline.where(
                                      (event) => event.id == eventType.id)
                                ])),
                  ]),
                ),
              SizedBox(
                  width: 360,
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      Text("Driving Tendencies",
                          style: Theme.of(context).textTheme.titleMedium),
                      FieldHeatMap(
                          useRedNormalized: false,
                          events: match.robot.values.fold(
                              [],
                              (previousValue, element) => [
                                    ...previousValue,
                                    ...element.timelineInterpolated
                                        .where((event) => event.isPositionEvent)
                                  ])),
                    ],
                  )),
            ],
          )
        ],
      ),
    );
  }
}
