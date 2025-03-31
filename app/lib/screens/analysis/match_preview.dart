import 'dart:convert';

import 'package:app/services/snout_image_cache.dart';
import 'package:app/widgets/datasheet.dart';
import 'package:app/providers/data_provider.dart';
import 'package:app/widgets/fieldwidget.dart';
import 'package:app/style.dart';
import 'package:app/screens/view_team_page.dart';
import 'package:app/widgets/image_view.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:snout_db/config/surveyitem.dart';
import 'package:snout_db/event/frcevent.dart';
import 'package:snout_db/snout_db.dart';

class AnalysisMatchPreview extends StatefulWidget {
  const AnalysisMatchPreview({
    super.key,
    required this.red,
    required this.blue,
    this.plan,
    this.matchLabel,
  });

  final String? matchLabel;
  final Widget? plan;
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
    final redController = TextEditingController(text: json.encode(_red));
    final blueController = TextEditingController(text: json.encode(_red));

    return Scaffold(
      appBar: AppBar(
        title:
            widget.matchLabel != null
                ? Text("${widget.matchLabel} Preview")
                : const Text("Match Preview"),
        actions: [
          TextButton(
            onPressed: () {
              showDialog(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: const Text("Set Teams"),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text("Red"),
                          TextField(controller: redController),
                          const SizedBox(height: 16),
                          const Text("Blue"),
                          TextField(controller: blueController),
                          FilledButton(
                            onPressed: () {
                              setState(() {
                                _red = List<int>.from(
                                  json.decode(redController.text),
                                );
                                _blue = List<int>.from(
                                  json.decode(blueController.text),
                                );
                              });
                            },
                            child: Text("Submit"),
                          ),
                        ],
                      ),
                    ),
              );
            },
            child: const Text("Edit Teams"),
          ),
        ],
      ),
      body: ListView(
        cacheExtent: 5000,
        children: [
          if (widget.plan != null) widget.plan!,
          DataSheet(
            title: "Alliance Sum of Avg",
            columns: [
              DataItemColumn(DataItem.fromText("Alliance")),
              for (final item in data.event.config.matchscouting.processes)
                DataItemColumn(
                  DataItem.fromText(item.label),
                  width: numericWidth,
                ),
            ],
            rows: [
              [
                const DataItem(
                  displayValue: Text(
                    "BLUE",
                    style: TextStyle(color: Colors.blue),
                  ),
                  exportValue: "BLUE",
                  sortingValue: "BLUE",
                ),
                for (final item in data.event.config.matchscouting.processes)
                  DataItem.fromNumber(
                    _blue.fold<double>(
                      0,
                      (previousValue, team) =>
                          previousValue +
                          (data.event.teamAverageProcess(team, item) ?? 0),
                    ),
                  ),
              ],
              [
                const DataItem(
                  displayValue: Text(
                    "RED",
                    style: TextStyle(color: Colors.red),
                  ),
                  exportValue: "RED",
                  sortingValue: "RED",
                ),
                for (final item in data.event.config.matchscouting.processes)
                  DataItem.fromNumber(
                    _red.fold<double>(
                      0,
                      (previousValue, team) =>
                          previousValue +
                          (data.event.teamAverageProcess(team, item) ?? 0),
                    ),
                  ),
              ],
            ],
          ),
          const Divider(height: 42),
          DataSheet(
            title: "Team Averages",
            columns: [
              DataItemColumn(DataItem.fromText("Team")),
              for (final item in data.event.config.matchscouting.processes)
                DataItemColumn(
                  DataItem.fromText(item.label),
                  largerIsBetter: item.isLargerBetter,
                  width: numericWidth,
                ),
              for (final item in data.event.config.matchscouting.survey)
                DataItemColumn(DataItem.fromText(item.label)),
            ],
            rows: [
              for (final team in [..._blue, ..._red])
                [
                  DataItem(
                    displayValue: TextButton(
                      child: Text(
                        team.toString(),
                        style: TextStyle(
                          color: getAllianceUIColor(
                            _red.contains(team) ? Alliance.red : Alliance.blue,
                          ),
                        ),
                      ),
                      onPressed:
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => TeamViewPage(teamNumber: team),
                            ),
                          ),
                    ),
                    exportValue: team.toString(),
                    sortingValue: team,
                  ),
                  for (final item in data.event.config.matchscouting.processes)
                    DataItem.fromNumber(
                      data.event.teamAverageProcess(team, item),
                    ),
                  for (final item in data.event.config.matchscouting.survey)
                    teamPostGameSurveyTableDisplay(data.event, team, item),
                ],
            ],
          ),
          const Divider(height: 32),
          ScrollConfiguration(
            behavior: MouseInteractableScrollBehavior(),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final (idx, team) in [..._blue, ..._red].indexed) ...[
                    Container(
                      color: (idx > 2 ? Colors.red : Colors.blue).withAlpha(
                        45 + ((idx % 2) * 45),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 250,
                            height: 250,
                            child:
                                context
                                            .read<DataProvider>()
                                            .event
                                            .pitscouting[team
                                            .toString()]?[robotPictureReserved] !=
                                        null
                                    ? AspectRatio(
                                      aspectRatio: 1,
                                      child: ImageViewer(
                                        child: Image(
                                          image: snoutImageCache.getCached(
                                            context
                                                .read<DataProvider>()
                                                .event
                                                .pitscouting[team
                                                .toString()]![robotPictureReserved]!,
                                          ),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    )
                                    : const Text("No image"),
                          ),
                          TextButton(
                            onPressed:
                                () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) =>
                                            TeamViewPage(teamNumber: team),
                                  ),
                                ),
                            child: Text(
                              team.toString(),
                              style: Theme.of(
                                context,
                              ).textTheme.titleLarge?.copyWith(
                                color: getAllianceUIColor(
                                  _red.contains(team)
                                      ? Alliance.red
                                      : Alliance.blue,
                                ),
                              ),
                            ),
                          ),
                          Column(
                            children: [
                              Text(
                                "Autos",
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              PathsViewer(
                                size: 280,
                                paths: [
                                  for (final match in data.event
                                      .teamRecordedMatches(team))
                                    (
                                      label:
                                          match.value
                                              .getSchedule(
                                                data.event,
                                                match.key,
                                              )
                                              ?.label ??
                                          match.key,
                                      path:
                                          match.value.robot[team.toString()]!
                                              .timelineInterpolatedBlueNormalized(
                                                data.event.config.fieldStyle,
                                              )
                                              .where(
                                                (element) => element.isInAuto,
                                              )
                                              .toList(),
                                    ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Column(
                            children: [
                              const SizedBox(height: 8),
                              Text(
                                "Starting Positions",
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              FieldHeatMap(
                                events:
                                    [
                                      for (final match in data.event
                                          .teamRecordedMatches(team))
                                        match.value.robot[team.toString()]!
                                            .timelineInterpolatedBlueNormalized(
                                              data.event.config.fieldStyle,
                                            )
                                            .where(
                                              (element) =>
                                                  element.isPositionEvent,
                                            )
                                            .first,
                                    ].nonNulls.toList(),
                              ),
                            ],
                          ),
                          Text(
                            "Autos Heatmap",
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          FieldHeatMap(
                            events: [
                              for (final match in data.event
                                  .teamRecordedMatches(team))
                                ...match.value.robot[team.toString()]!
                                    .timelineInterpolatedBlueNormalized(
                                      data.event.config.fieldStyle,
                                    )
                                    .where((element) => element.isInAuto),
                            ],
                          ),
                          for (final eventType
                              in data.event.config.matchscouting.events)
                            Column(
                              children: [
                                const SizedBox(height: 8),
                                Text(
                                  eventType.label,
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                FieldHeatMap(
                                  events: [
                                    for (final match in data.event
                                        .teamRecordedMatches(team))
                                      ...?match.value.robot[team.toString()]
                                          ?.timelineBlueNormalized(
                                            data.event.config.fieldStyle,
                                          )
                                          .where(
                                            (event) => event.id == eventType.id,
                                          ),
                                  ],
                                ),
                              ],
                            ),
                          Column(
                            children: [
                              const SizedBox(height: 8),
                              Text(
                                "Ending Positions",
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              FieldHeatMap(
                                events:
                                    [
                                      for (final match in data.event
                                          .teamRecordedMatches(team))
                                        match.value.robot[team.toString()]!
                                            .timelineInterpolatedBlueNormalized(
                                              data.event.config.fieldStyle,
                                            )
                                            .where(
                                              (element) =>
                                                  element.isPositionEvent,
                                            )
                                            .last,
                                    ].nonNulls.toList(),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              const SizedBox(height: 8),
                              Text(
                                "Driving Tendencies",
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              FieldHeatMap(
                                events: [
                                  for (final match in data.event
                                      .teamRecordedMatches(team))
                                    ...match.value.robot[team.toString()]!
                                        .timelineInterpolatedBlueNormalized(
                                          data.event.config.fieldStyle,
                                        )
                                        .where(
                                          (event) => event.isPositionEvent,
                                        ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

DataItem teamPostGameSurveyTableDisplay(
  FRCEvent event,
  int team,
  SurveyItem surveyItem,
) {
  final recordedMatches = event.teamRecordedMatches(team).toList();

  if (surveyItem.type == SurveyItemType.selector) {
    final Map<String, double> toReturn = {};

    for (final match in recordedMatches) {
      final surveyValue =
          match.value.robot[team.toString()]!.survey[surveyItem.id]?.toString();
      if (surveyValue == null) {
        continue;
      }
      if (toReturn[surveyValue] == null) {
        toReturn[surveyValue] = 1;
      } else {
        toReturn[surveyValue] = toReturn[surveyValue]! + 1;
      }
    }

    //Convert the map to be a percentage rather than total sum
    return DataItem.fromText(
      toReturn.entries
          .sorted((a, b) => Comparable.compare(b.value, a.value))
          .fold<String>(
            "",
            (previousValue, element) =>
                "${previousValue == "" ? "" : "$previousValue\n"} ${element.value}: ${element.key}",
          ),
    );
  }

  if (surveyItem.type == SurveyItemType.picture) {
    return DataItem.fromText("See team page or Robot recordings");
  }

  String result = "";
  // Reversed to display the most recent match first in the table
  for (final match in recordedMatches.reversed) {
    final surveyValue =
        match.value.robot[team.toString()]!.survey[surveyItem.id]?.toString();

    if (surveyValue == null) {
      continue;
    }

    result +=
        '${match.value.getSchedule(event, match.key)?.label ?? match.key}: $surveyValue\n';
  }

  return DataItem.fromText(result);
}
