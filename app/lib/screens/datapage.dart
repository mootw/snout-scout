import 'dart:ui';

import 'package:app/main.dart';
import 'package:app/screens/view_team_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:snout_db/config/surveyitem.dart';

//TODO make this non-repetitive. It generates a sorting table, columns, and data seprately in the same way.

class DataTablePage extends StatefulWidget {
  const DataTablePage({super.key});

  @override
  State<DataTablePage> createState() => _DataTablePageState();
}

class _DataTablePageState extends State<DataTablePage> {
  int _currentSortColumn = 0;
  bool _sortAscending = true;

  void updateSort(columnIndex, ascending) {
    setState(() {
      _currentSortColumn = columnIndex;
      _sortAscending = ascending;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EventDB>(builder: (context, snoutData, child) {
      //TODO fix ugly sorting code
      List<int> teamsSorted = snoutData.db.teams.toList();

      List<List<double>> sortValues = List.generate(
        2 +
            snoutData.db.config.matchscouting.events.length,
        (column) {
          //Column
          return List.generate(teamsSorted.length, (row) {
            //Row
            double value = <Function(int)>[
              //Team Row
              (team) => team,
              //Matches
              (team) => snoutData.db
                  .matchesWithTeam(team)
                  .where((element) => element.results != null)
                  .length,
              for (final eventType in snoutData.db.config.matchscouting.events)
                (team) => (snoutData.db.matchesWithTeam(team).fold<int>(
                        0,
                        (previousValue, match) =>
                            previousValue +
                            (match.robot[team.toString()]?.timeline
                                    .where((event) => event.id == eventType.id)
                                    .length ??
                                0)) /
                    snoutData.db
                        .matchesWithTeam(team)
                        .where(
                            (element) => element.robot[team.toString()] != null)
                        .length),
            ][column](teamsSorted[row])?.toDouble();
            if (value.isNaN) {
              //Less than zero value to stort all the way at the bottom
              return -1;
            } else {
              return value;
            }
          });
        },
      );

      teamsSorted.sort((a, b) => _sortAscending
          ? sortValues[_currentSortColumn][sortValues[0].indexOf(a.toDouble())].round() -
              sortValues[_currentSortColumn][sortValues[0].indexOf(b.toDouble())].round()
          : sortValues[_currentSortColumn][sortValues[0].indexOf(b.toDouble())].round() -
              sortValues[_currentSortColumn][sortValues[0].indexOf(a.toDouble())].round());

      return ListView(
        children: [
          ScrollConfiguration(
            behavior: MouseInteractableScrollBehavior(),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                sortAscending: _sortAscending,
                sortColumnIndex: _currentSortColumn,
                columns: [
                  DataColumn(label: const Text("Team"), onSort: updateSort),
                  DataColumn(label: const Text("Played"), onSort: updateSort),
                  for (final eventType
                      in snoutData.db.config.matchscouting.events)
                    DataColumn(
                        label: Text("avg\n${eventType.label}"),
                        onSort: updateSort),
                  for (final pitSurvey in snoutData.db.config.pitscouting.where(
                      (element) => element.type != SurveyItemType.picture))
                    DataColumn(
                        label: Text("Pit Scouting:\n${pitSurvey.label}")),
                ],
                rows: [
                  for (final team in teamsSorted)
                    DataRow(cells: [
                      DataCell(TextButton(
                        child: Text(team.toString()),
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
                                        (match.robot[team.toString()]?.timeline
                                                .where((event) =>
                                                    event.id == eventType.id)
                                                .length ??
                                            0)) /
                            snoutData.db
                                .matchesWithTeam(team)
                                .where((element) =>
                                    element.robot[team.toString()] != null)
                                .length)))),
                      for (final pitSurvey in snoutData.db.config.pitscouting
                          .where((element) =>
                              element.type != SurveyItemType.picture))
                        DataCell(Text(snoutData
                                .db.pitscouting[team.toString()]?[pitSurvey.id]
                                ?.toString() ??
                            "No Data")),
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

String numDisplay(double? input) {
  if (input == null || input.isNaN) {
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
