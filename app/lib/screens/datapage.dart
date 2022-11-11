import 'dart:ui';

import 'package:app/main.dart';
import 'package:app/screens/view_team_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
          Text(
              "Display a spreadsheet like table with every metric (including performance metrics for ranking like win-loss) and allow sorting and filtering of the data"),
          ScrollConfiguration(
            behavior: MyCustomScrollBehavior(),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: [
                  DataColumn(label: Text("Team")),
                  DataColumn(label: Text("Played")),
                  for (final eventType
                      in snoutData.season.matchscouting.uniqueEventIds)
                    DataColumn(label: Text("avg $eventType")),
                ],
                rows: [
                  for (final team in snoutData.currentEvent.teams)
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
                      DataCell(Text(snoutData.currentEvent
                          .matchesWithTeam(team)
                          .where((element) => element.results != null)
                          .length
                          .toString())),
                      for (final eventType
                          in snoutData.season.matchscouting.uniqueEventIds)
                        DataCell(Text(numDisplay((snoutData.currentEvent
                                    .matchesWithTeam(team)
                                    .fold<int>(
                                        0,
                                        (previousValue, match) =>
                                            previousValue +
                                            (match.robot[team.toString()]
                                                    ?.timeline
                                                    .where((event) =>
                                                        event.id == eventType)
                                                    .length ??
                                                0)) /
                                snoutData.currentEvent
                                    .matchesWithTeam(team)
                                    .where((element) =>
                                        element.robot[team.toString()] != null)
                                    .length)
                            ))),
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
  return input.round().toString();
}

class MyCustomScrollBehavior extends MaterialScrollBehavior {
  // Override behavior methods and getters like dragDevices
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        // etc.
      };
}
