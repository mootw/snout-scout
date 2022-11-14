import 'dart:ui';

import 'package:app/main.dart';
import 'package:app/screens/view_team_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:snout_db/config/surveyitem.dart';

class DataTablePage extends StatefulWidget {
  const DataTablePage({super.key});

  @override
  State<DataTablePage> createState() => _DataTablePageState();
}

class _DataTablePageState extends State<DataTablePage> {
  @override
  Widget build(BuildContext context) {
    return Consumer<SnoutScoutData>(builder: (context, snoutData, child) {
      return ListView(
        children: [
          const Text(
              "Display a spreadsheet like table with every metric (including performance metrics for ranking like win-loss) and allow sorting and filtering of the data"),
          ScrollConfiguration(
            behavior: MouseInteractableScrollBehavior(),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: [
                  const DataColumn(label: Text("Team")),
                  const DataColumn(label: Text("Played")),
                  for (final eventType
                      in snoutData.db.config.matchscouting.events)
                    DataColumn(label: Text("avg\n${eventType.label}")),

                  for (final pitSurvey
                      in snoutData.db.config.pitscouting.where((element) => element.type != SurveyItemType.picture))
                    DataColumn(label: Text("Pit Scouting:\n${pitSurvey.label}")),
                ],
                rows: [
                  for (final team in snoutData.db.teams)
                    DataRow(cells: [
                      DataCell(TextButton(child: Text(team.toString()), onPressed: () {
                        //Open this teams scouting page
                        Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        TeamViewPage(teamNumber: team)),
                              );
                      },)),
                      DataCell(Text(snoutData.db
                          .matchesWithTeam(team)
                          .where((element) => element.results != null)
                          .length
                          .toString())),
                      for (final eventType
                          in snoutData.db.config.matchscouting.events)
                        DataCell(Text(numDisplay((snoutData.db
                                    .matchesWithTeam(team)
                                    .fold<int>(
                                        0,
                                        (previousValue, match) =>
                                            previousValue +
                                            (match.robot[team.toString()]
                                                    ?.timeline
                                                    .where((event) =>
                                                        event.id == eventType.id)
                                                    .length ??
                                                0)) /
                                snoutData.db
                                    .matchesWithTeam(team)
                                    .where((element) =>
                                        element.robot[team.toString()] != null)
                                    .length)
                            ))),
                      for (final pitSurvey
                        in snoutData.db.config.pitscouting.where((element) => element.type != SurveyItemType.picture))
                          DataCell(Text(snoutData.db.pitscouting[team.toString()]?[pitSurvey.id]?.toString() ?? "No Data")),
                    ])
                ],
              ),
            ),
          ),
        ],
      );
    });
  }
}

String numDisplay (double? input) {
  if(input == null || input.isNaN) {
    return "No Data";
  }
  return ((input * 10).round() / 10).toString();
}

class MouseInteractableScrollBehavior extends MaterialScrollBehavior {
  // Override behavior methods and getters like dragDevices
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        // etc.
      };
}
