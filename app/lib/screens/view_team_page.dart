import 'dart:convert';
import 'dart:typed_data';

import 'package:app/datasheet.dart';
import 'package:app/edit_lock.dart';
import 'package:app/eventdb_state.dart';
import 'package:app/fieldwidget.dart';
import 'package:app/helpers.dart';
import 'package:app/match_card.dart';
import 'package:app/screens/match_page.dart';
import 'package:app/screens/scout_team.dart';
import 'package:app/scouting_tools/scouting_tool.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:snout_db/event/match.dart';
import 'package:snout_db/event/pitscoutresult.dart';
import 'package:snout_db/config/surveyitem.dart';

class TeamViewPage extends StatefulWidget {
  final int teamNumber;

  const TeamViewPage({super.key, required this.teamNumber});

  @override
  State<TeamViewPage> createState() => _TeamViewPageState();
}

class _TeamViewPageState extends State<TeamViewPage> {
  @override
  Widget build(BuildContext context) {
    final data = context.watch<EventDB>();
    return Scaffold(
        appBar: AppBar(
          actions: [
            TextButton(
                onPressed: () async {
                  //Get existing scouting data.
                  final result = await navigateWithEditLock(
                      context,
                      "scoutteam:${widget.teamNumber}",
                      () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => PitScoutTeamPage(
                                    team: widget.teamNumber,
                                    config: data.db.config,
                                    oldData: data.db.pitscouting[
                                        widget.teamNumber.toString()])),
                          ));
                  if (result != null) {
                    //Data has been saved
                    setState(() {});
                  }
                },
                child: const Text("Scout"))
          ],
          title: Text("Team ${widget.teamNumber}"),
        ),
        body: ListView(
          cacheExtent: 5000,
          children: [
            ScoutingResultsViewer(
                teamNumber: widget.teamNumber, snoutData: data),
            const Divider(height: 32),
            //Display this teams matches

            DataSheet(
              title: 'Metrics',
              //Data is a list of rows and columns
              columns: [
                DataItem.fromText("Metric"),
                for (final event in data.db.config.matchscouting.events)
                  DataItem.fromText(event.label),
              ],
              rows: [
                [
                  DataItem.fromText("All"),
                  for (final event in data.db.config.matchscouting.events)
                    DataItem.fromNumber(
                        data.db.teamAverageMetric(widget.teamNumber, event.id)),
                ],
                [
                  DataItem.fromText("Auto"),
                  for (final eventType in data.db.config.matchscouting.events)
                    DataItem.fromNumber(data.db.teamAverageMetric(
                        widget.teamNumber,
                        eventType.id,
                        (event) => event.isInAuto)),
                ]
              ],
            ),

            const Divider(height: 32),
            DataSheet(
              title: 'Matches',
              //Data is a list of rows and columns
              columns: [
                DataItem.fromText("Match"),
                for (final item in data.db.config.matchscouting.processes)
                  DataItem.fromText(item.label),
                for (final pitSurvey in data.db.config.matchscouting.postgame
                    .where((element) => element.type != SurveyItemType.picture))
                  DataItem.fromText(pitSurvey.label),
              ],
              rows: [
                //Show ALL matches the team is scheduled for ALONG with all matches they played regardless of it it is scheduled sorted
                for (final match in <FRCMatch>{
                  ...data.db.matchesWithTeam(widget.teamNumber),
                  ...data.db
                      .teamRecordedMatches(widget.teamNumber)
                      .map((e) => e.value)
                }.sorted((a, b) => Comparable.compare(a, b)))
                  [
                    DataItem(
                        displayValue: TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => MatchPage(
                                        matchid:
                                            data.db.matchIDFromMatch(match))),
                              );
                            },
                            child: Text(
                              match.description,
                              style: TextStyle(
                                  color: getAllianceColor(
                                      match.getAllianceOf(widget.teamNumber))),
                            )),
                        exportValue: match.description,
                        sortingValue: match),
                    for (final item
                        in data.db.config.matchscouting.processes)
                      DataItem.fromNumber(data.db.runMatchResultsProcess(item,
                          match.robot[widget.teamNumber.toString()], widget.teamNumber)),
                    for (final pitSurvey in data
                        .db.config.matchscouting.postgame
                        .where((element) =>
                            element.type != SurveyItemType.picture))
                      DataItem.fromText(match
                          .robot[widget.teamNumber.toString()]
                          ?.survey[pitSurvey.id]
                          ?.toString()),
                  ],
              ],
            ),

            const Divider(height: 16),

            Wrap(
              spacing: 12,
              alignment: WrapAlignment.center,
              children: [
                SizedBox(
                  width: largeFieldSize,
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      Text("Autos",
                          style: Theme.of(context).textTheme.titleMedium),
                      FieldPaths(
                        paths: [
                          for (final match
                              in data.db.teamRecordedMatches(widget.teamNumber))
                            match.value.robot[widget.teamNumber.toString()]!
                                .timelineInterpolatedRedNormalized(data.db.config.fieldStyle)
                                .where((element) => element.isInAuto)
                                .toList()
                        ],
                      ),
                    ],
                  ),
                ),
                for (final eventType in data.db.config.matchscouting.events)
                  SizedBox(
                    width: smallFieldSize,
                    child: Column(children: [
                      const SizedBox(height: 16),
                      Text(eventType.label,
                          style: Theme.of(context).textTheme.titleMedium),
                      FieldHeatMap(
                          events: data.db
                              .teamRecordedMatches(widget.teamNumber)
                              .fold(
                                  [],
                                  (previousValue, element) => [
                                        ...previousValue,
                                        ...?element
                                            .value
                                            .robot[widget.teamNumber.toString()]
                                            ?.timelineRedNormalized(data.db.config.fieldStyle)
                                            .where((event) =>
                                                event.id == eventType.id)
                                      ])),
                    ]),
                  ),
                SizedBox(
                    width: smallFieldSize,
                    child: Column(
                      children: [
                        const SizedBox(height: 16),
                        Text("Driving Tendencies",
                            style: Theme.of(context).textTheme.titleMedium),
                        FieldHeatMap(
                            events: data.db
                                .teamRecordedMatches(widget.teamNumber)
                                .fold(
                                    [],
                                    (previousValue, element) => [
                                          ...previousValue,
                                          ...?element
                                              .value
                                              .robot[
                                                  widget.teamNumber.toString()]
                                              ?.timelineInterpolatedRedNormalized(data.db.config.fieldStyle)
                                              .where((event) =>
                                                  event.isPositionEvent)
                                        ])),
                      ],
                    )),
                const Divider(height: 32),
                Center(
                    child: Text("Schedule",
                        style: Theme.of(context).textTheme.titleLarge)),
                for (final match in data.db.matchesWithTeam(widget.teamNumber))
                  MatchCard(match: match, focusTeam: widget.teamNumber),
              ],
            ),
          ],
        ));
  }
}

class ScoutingResultsViewer extends StatelessWidget {
  final int teamNumber;
  final EventDB snoutData;

  const ScoutingResultsViewer(
      {super.key, required this.teamNumber, required this.snoutData});

  @override
  Widget build(BuildContext context) {
    final data = snoutData.db.pitscouting[teamNumber.toString()];
    if (data == null) {
      return const ListTile(title: Text("Team has no pit scouting data"));
    }
    return Column(
      children: [
        for (final item in snoutData.db.config.pitscouting)
          ScoutingResult(item: item, survey: data)
      ],
    );
  }
}

class ScoutingResult extends StatelessWidget {
  final SurveyItem item;
  final PitScoutResult survey;

  const ScoutingResult({super.key, required this.item, required this.survey});

  dynamic get value => survey[item.id];

  @override
  Widget build(BuildContext context) {
    if (value == null) {
      return Container();
    }

    if (item.type == SurveyItemType.picture) {
      return ListTile(
        title: Text(item.label),
        subtitle: SizedBox(
            height: scoutImageSize,
            child: Image.memory(
              Uint8List.fromList(base64Decode(value).cast<int>()),
            )),
      );
    }

    return ListTile(
      title: Text(item.label),
      subtitle: Text(value.toString()),
    );
  }
}
