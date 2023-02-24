import 'package:app/datasheet.dart';
import 'package:app/helpers.dart';
import 'package:app/main.dart';
import 'package:app/screens/view_team_page.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:snout_db/event/match.dart';
import 'package:snout_db/snout_db.dart';

class AnalysisMatchPreview extends StatefulWidget {
  const AnalysisMatchPreview({super.key});

  @override
  State<AnalysisMatchPreview> createState() => _AnalysisMatchPreviewState();
}

class _AnalysisMatchPreviewState extends State<AnalysisMatchPreview> {
  List<int> red = [];
  List<int> blue = [];

  FRCMatch? selectedMatch;

  @override
  Widget build(BuildContext context) {
    final data = context.watch<EventDB>();
    return Scaffold(
      appBar: AppBar(title: const Text("Match Preview")),
      body: ListView(
        children: [
          DropdownButton<FRCMatch>(
            value: selectedMatch,
            onChanged: (FRCMatch? value) {
              // This is called when the user selects an item.
              setState(() {
                selectedMatch = value!;
              });

              red = selectedMatch!.red;
              blue = selectedMatch!.blue;
            },
            items: data.db.matches.values
                .map<DropdownMenuItem<FRCMatch>>((FRCMatch value) {
              return DropdownMenuItem<FRCMatch>(
                value: value,
                child: Text(value.description),
              );
            }).toList(),
          ),
          const Text(
              "Show a table of each robot in the match and their average performance for each metric, along with some pit scouting data to see where they intake from and stuff???"),
          const SizedBox(height: 32),
          DataSheet(title: "Sum Alliance Average", columns: [
            DataItem.fromText("Alliance"),
            for (final item in data.db.config.matchscouting.events)
              DataItem.fromText(item.label),
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
            ]
          ]),
          const Divider(height: 42),
          DataSheet(title: "Team Averages", columns: [
            DataItem.fromText("Team"),
            for (final item in data.db.config.matchscouting.events)
              DataItem.fromText(item.label),
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
                for (final item in data.db.config.matchscouting.postgame)
                  //Get the frequency of events and then pick the highest frequency one.
                  // DataItem.fromText(data.db
                  //     .teamPostGameSurveyByFrequency(team, item.id)
                  //     .entries
                  //     .fold<MapEntry<String, double>>(
                  //         MapEntry(noDataText, 0),
                  //         (previousValue, element) =>
                  //             element.value > previousValue.value
                  //                 ? element
                  //                 : previousValue)
                  //     .toString()),
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
          const Text(
              "Also display data about the team's post game survey since it can include important details like climbing"),
          const Text(
              "Show heatmaps for each alliance/team to see their autos and scoring"),
        ],
      ),
    );
  }
}
