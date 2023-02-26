import 'dart:convert';

import 'package:app/datasheet.dart';
import 'package:app/fieldwidget.dart';
import 'package:app/helpers.dart';
import 'package:app/main.dart';
import 'package:app/screens/view_team_page.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:snout_db/snout_db.dart';

class AnalysisMatchPreview extends StatefulWidget {
  const AnalysisMatchPreview(
      {super.key, required this.red, required this.blue});

  final List<int> red;
  final List<int> blue;

  @override
  State<AnalysisMatchPreview> createState() => _AnalysisMatchPreviewState();
}

class _AnalysisMatchPreviewState extends State<AnalysisMatchPreview> {
  List<int> red = [];
  List<int> blue = [];

  @override
  void initState() {
    super.initState();
    red = widget.red;
    blue = widget.blue;
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<EventDB>();
    return Scaffold(
      appBar: AppBar(title: const Text("Match Preview"), actions: [
        TextButton(
            onPressed: () {
              showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                        title: const Text("PRESS ENTER TO 'SUBMIT' THE CHANGE"),
                        content:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                          const Text("Red"),
                          TextField(
                            controller:
                                TextEditingController(text: jsonEncode(red)),
                            onSubmitted: (value) {
                              setState(() {
                                red = List<int>.from(jsonDecode(value));
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          const Text("Blue"),
                          TextField(
                            controller:
                                TextEditingController(text: jsonEncode(blue)),
                            onSubmitted: (value) {
                              setState(() {
                                blue = List<int>.from(jsonDecode(value));
                              });
                            },
                          )
                        ]),
                      ));
            },
            child: const Text("Edit Teams"))
      ]),
      body: ListView(
        children: [
          DataSheet(title: "Sum Alliance Average", columns: [
            DataItem.fromText("Alliance"),
            for (final item in data.db.config.matchscouting.events)
              DataItem.fromText(item.label),
            for (final item in data.db.config.matchscouting.events)
              DataItem.fromText("Auto:\n${item.label}"),
          ], rows: [
            [
              DataItem(
                  displayValue:
                      const Text("RED", style: TextStyle(color: Colors.red)),
                  exportValue: "RED",
                  sortingValue: "RED"),
              for (final event in data.db.config.matchscouting.events)
                DataItem.fromNumber(red.fold<double>(
                    0,
                    (previousValue, team) =>
                        previousValue +
                        (data.db.teamAverageMetric(team, event.id) ?? 0))),
              for (final event in data.db.config.matchscouting.events)
                DataItem.fromNumber(red.fold<double>(
                    0,
                    (previousValue, team) =>
                        previousValue +
                        (data.db.teamAverageMetric(
                                team, event.id, (event) => event.isInAuto) ??
                            0))),
            ],
            [
              DataItem(
                  displayValue:
                      const Text("BLUE", style: TextStyle(color: Colors.blue)),
                  exportValue: "BLUE",
                  sortingValue: "BLUE"),
              for (final event in data.db.config.matchscouting.events)
                DataItem.fromNumber(blue.fold<double>(
                    0,
                    (previousValue, team) =>
                        previousValue +
                        (data.db.teamAverageMetric(team, event.id) ?? 0))),
              for (final event in data.db.config.matchscouting.events)
                DataItem.fromNumber(blue.fold<double>(
                    0,
                    (previousValue, team) =>
                        previousValue +
                        (data.db.teamAverageMetric(
                                team, event.id, (event) => event.isInAuto) ??
                            0))),
            ]
          ]),
          const Divider(height: 42),
          DataSheet(title: "Team Averages", columns: [
            DataItem.fromText("Team"),
            for (final item in data.db.config.matchscouting.events)
              DataItem.fromText(item.label),
            for (final item in data.db.config.matchscouting.events)
              DataItem.fromText("AUTO\n${item.label}"),
            for (final item in data.db.config.matchscouting.postgame)
              DataItem.fromText(item.label),
          ], rows: [
            for (final team in [...red, ...blue])
              [
                DataItem(
                    displayValue: TextButton(
                      child: Text(team.toString(),
                          style: TextStyle(
                              color: getAllianceColor(red.contains(team)
                                  ? Alliance.red
                                  : Alliance.blue))),
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
                for (final eventType in data.db.config.matchscouting.events)
                  DataItem.fromNumber(
                      data.db.teamAverageMetric(team, eventType.id)),
                for (final eventType in data.db.config.matchscouting.events)
                  DataItem.fromNumber(data.db.teamAverageMetric(
                      team, eventType.id, (event) => event.isInAuto)),
                for (final item in data.db.config.matchscouting.postgame)
                  DataItem.fromText(data.db
                      .teamPostGameSurveyByFrequency(team, item.id)
                      .entries
                      .sorted((a, b) => Comparable.compare(a.value, b.value))
                      .fold<String>(
                          "",
                          (previousValue, element) =>
                              "${previousValue == "" ? "" : "$previousValue\n"} ${(element.value * 100).round()}% ${element.key}")),
              ]
          ]),
          const Divider(height: 32),
          ScrollConfiguration(
            behavior: MouseInteractableScrollBehavior(),
            child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final team in [...red, ...blue]) ...[
                      const SizedBox(width: 8),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(team.toString(),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                      color: getAllianceColor(red.contains(team)
                                          ? Alliance.red
                                          : Alliance.blue))),
                          SizedBox(
                            width: 300,
                            child: Column(
                              children: [
                                const SizedBox(height: 16),
                                Text("Autos",
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium),
                                FieldPaths(
                                  key: UniqueKey(),
                                  paths: [
                                    for (final match
                                        in data.db.teamRecordedMatches(team!))
                                      match.value.robot[team.toString()]!
                                          .timelineInterpolated
                                          .where((element) => element.isInAuto)
                                          .toList()
                                  ],
                                ),
                              ],
                            ),
                          ),
                          for (final eventType
                              in data.db.config.matchscouting.events)
                            SizedBox(
                              width: 300,
                              child: Column(children: [
                                const SizedBox(height: 16),
                                Text(eventType.label,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium),
                                FieldHeatMap(
                                    key: UniqueKey(),
                                    useRedNormalized: true,
                                    events:
                                        data.db.teamRecordedMatches(team).fold(
                                            [],
                                            (previousValue, element) => [
                                                  ...previousValue,
                                                  ...?element
                                                      .value
                                                      .robot[team.toString()]
                                                      ?.timeline
                                                      .where((event) =>
                                                          event.id ==
                                                          eventType.id)
                                                ])),
                              ]),
                            ),
                          SizedBox(
                              width: 300,
                              child: Column(
                                children: [
                                  const SizedBox(height: 16),
                                  Text("Driving Tendencies",
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium),
                                  FieldHeatMap(
                                      useRedNormalized: true,
                                      events: data.db
                                          .teamRecordedMatches(team)
                                          .fold(
                                              [],
                                              (previousValue, element) => [
                                                    ...previousValue,
                                                    ...?element
                                                        .value
                                                        .robot[team.toString()]
                                                        ?.timelineInterpolated
                                                        .where((event) => event
                                                            .isPositionEvent)
                                                  ])),
                                ],
                              )),
                        ],
                      ),
                      const SizedBox(width: 8),
                    ]
                  ],
                )),
          ),
        ],
      ),
    );
  }
}
