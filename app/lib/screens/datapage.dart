import 'dart:ui';

import 'package:app/main.dart';
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
                ],
                rows: [
                  for (final team in snoutData.currentEvent.teams)
                    DataRow(cells: [
                      DataCell(Text(team.toString())),
                      DataCell(Text(snoutData.currentEvent
                          .matchesWithTeam(team)
                          .where((element) => element.results != null)
                          .length
                          .toString())),
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

class MyCustomScrollBehavior extends MaterialScrollBehavior {
  // Override behavior methods and getters like dragDevices
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        // etc.
      };
}
