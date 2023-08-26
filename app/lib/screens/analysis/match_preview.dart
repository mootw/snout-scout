import 'dart:convert';
import 'dart:typed_data';

import 'package:app/widgets/datasheet.dart';
import 'package:app/providers/data_provider.dart';
import 'package:app/widgets/fieldwidget.dart';
import 'package:app/helpers.dart';
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
  List<int> _red = [];
  List<int> _blue = [];

  @override
  void initState() {
    super.initState();
    _red = widget.red;
    _blue = widget.blue;
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
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
                                TextEditingController(text: json.encode(_red)),
                            onSubmitted: (value) {
                              setState(() {
                                _red = List<int>.from(json.decode(value));
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          const Text("Blue"),
                          TextField(
                            controller:
                                TextEditingController(text: json.encode(_blue)),
                            onSubmitted: (value) {
                              setState(() {
                                _blue = List<int>.from(json.decode(value));
                              });
                            },
                          )
                        ]),
                      ));
            },
            child: const Text("Edit Teams"))
      ]),
      body: ListView(
        cacheExtent: 5000,
        children: [
          DataSheet(title: "Alliance Sum of Avg", columns: [
            DataItem.fromText("Alliance"),
            for (final item in data.event.config.matchscouting.processes)
              DataItem.fromText(item.label),
          ], rows: [
            [
              const DataItem(
                  displayValue:
                      Text("RED", style: TextStyle(color: Colors.red)),
                  exportValue: "RED",
                  sortingValue: "RED"),
              for (final item in data.event.config.matchscouting.processes)
                DataItem.fromNumber(_red.fold<double>(
                    0,
                    (previousValue, team) =>
                        previousValue +
                        (data.event.teamAverageProcess(team, item) ?? 0))),
            ],
            [
              const DataItem(
                  displayValue:
                      Text("BLUE", style: TextStyle(color: Colors.blue)),
                  exportValue: "BLUE",
                  sortingValue: "BLUE"),
              for (final item in data.event.config.matchscouting.processes)
                DataItem.fromNumber(_blue.fold<double>(
                    0,
                    (previousValue, team) =>
                        previousValue +
                        (data.event.teamAverageProcess(team, item) ?? 0))),
            ]
          ]),
          const Divider(height: 42),
          DataSheet(title: "Team Averages", columns: [
            DataItem.fromText("Team"),
            for (final item in data.event.config.matchscouting.processes)
              DataItem.fromText(item.label),
            for (final item in data.event.config.matchscouting.survey)
              DataItem.fromText(item.label),
          ], rows: [
            for (final team in [..._red, ..._blue])
              [
                DataItem(
                    displayValue: TextButton(
                      child: Text(team.toString(),
                          style: TextStyle(
                              color: getAllianceColor(_red.contains(team)
                                  ? Alliance.red
                                  : Alliance.blue))),
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  TeamViewPage(teamNumber: team))),
                    ),
                    exportValue: team.toString(),
                    sortingValue: team),
                for (final item in data.event.config.matchscouting.processes)
                  DataItem.fromNumber(
                      data.event.teamAverageProcess(team, item)),
                for (final item in data.event.config.matchscouting.survey)
                  DataItem.fromText(data.event
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
                    for (final team in [..._red, ..._blue]) ...[
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 250,
                            height: 250,
                            child: context
                                      .read<DataProvider>()
                                      .event
                                      .pitscouting[team.toString()]
                                  ?[robotPictureReserved] !=
                              null ? AspectRatio(
                              aspectRatio: 1,
                              child: Image.memory(
                                fit: BoxFit.cover,
                                Uint8List.fromList(base64Decode(context
                                            .read<DataProvider>()
                                            .event
                                            .pitscouting[team.toString()]![
                                        robotPictureReserved]!)
                                    .cast<int>()),
                              ),
                            ) : const Text("No image"),
                          ),
                          TextButton(
                              onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          TeamViewPage(teamNumber: team))),
                              child: Text(team.toString(),
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                          color: getAllianceColor(
                                              _red.contains(team)
                                                  ? Alliance.red
                                                  : Alliance.blue)))),
                          SizedBox(
                            width: 300,
                            child: Column(
                              children: [
                                Text("Autos",
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium),
                                FieldPaths(
                                  key: UniqueKey(),
                                  paths: [
                                    for (final match
                                        in data.event.teamRecordedMatches(team))
                                      match.value.robot[team.toString()]!
                                          .timelineInterpolatedRedNormalized(
                                              data.event.config.fieldStyle)
                                          .where((element) => element.isInAuto)
                                          .toList()
                                  ],
                                ),
                              ],
                            ),
                          ),
                          for (final eventType
                              in data.event.config.matchscouting.events)
                            SizedBox(
                              width: smallFieldSize,
                              child: Column(children: [
                                const SizedBox(height: 8),
                                Text(eventType.label,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium),
                                FieldHeatMap(
                                    key: UniqueKey(),
                                    events: data.event
                                        .teamRecordedMatches(team)
                                        .fold(
                                            [],
                                            (previousValue, element) => [
                                                  ...previousValue,
                                                  ...?element.value
                                                      .robot[team.toString()]
                                                      ?.timelineRedNormalized(
                                                          data.event.config
                                                              .fieldStyle)
                                                      .where((event) =>
                                                          event.id ==
                                                          eventType.id)
                                                ])),
                              ]),
                            ),
                          SizedBox(
                              width: smallFieldSize,
                              child: Column(
                                children: [
                                  const SizedBox(height: 8),
                                  Text("Driving Tendencies",
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium),
                                  FieldHeatMap(
                                      events: data.event
                                          .teamRecordedMatches(team)
                                          .fold(
                                              [],
                                              (previousValue, element) => [
                                                    ...previousValue,
                                                    ...?element.value
                                                        .robot[team.toString()]
                                                        ?.timelineInterpolatedRedNormalized(
                                                            data.event.config
                                                                .fieldStyle)
                                                        .where((event) => event
                                                            .isPositionEvent)
                                                  ])),
                                ],
                              )),
                        ],
                      ),
                    ]
                  ],
                )),
          ),
        ],
      ),
    );
  }
}
