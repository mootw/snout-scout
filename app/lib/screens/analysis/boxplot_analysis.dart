import 'dart:collection';

import 'package:app/screens/analysis/boxplot.dart';
import 'package:app/eventdb_state.dart';
import 'package:app/screens/view_team_page.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:snout_db/config/matchresults_process.dart';

class BoxPlotAnalysis extends StatefulWidget {
  const BoxPlotAnalysis({super.key});

  @override
  State<BoxPlotAnalysis> createState() => _BoxPlotAnalysisState();
}

class _BoxPlotAnalysisState extends State<BoxPlotAnalysis> {
  MatchResultsProcess? _selectedProcess;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<EventDB>();

    Map<int, List<num>>? teamValues;
    if (_selectedProcess != null) {
      teamValues = Map.fromEntries([
        for (final team in data.db.teams)
          MapEntry(team, [
            for (final match in data.db.teamRecordedMatches(team))
              data.db.runMatchResultsProcess(_selectedProcess!,
                      match.value.robot[team.toString()], team) ??
                  0
          ])
      ]);
    }

    //Sort hte numbers
    if (teamValues != null) {
      for (final value in teamValues.values) {
        value.sort();
      }
    }

    //Calculate the min and max values in the set
    num min = teamValues?.values.fold(
            0,
            (previousValue, element) => element.isEmpty
                ? (previousValue ?? 0)
                : previousValue! < element.min
                    ? previousValue
                    : element.min) ??
        0;
    num max = teamValues?.values.fold(
            0,
            (previousValue, element) => element.isEmpty
                ? (previousValue ?? 0)
                : previousValue! > element.max
                    ? previousValue
                    : element.max) ??
        0;

    print(min);
    print(max);

    //Sort them by the average
    SplayTreeMap<int, List<num>>? valuesSorted;
    if (teamValues != null) {
      valuesSorted =
          SplayTreeMap<int, List<num>>.from(teamValues, (key1, key2) {
        final a = teamValues?[key2];
        final b = teamValues?[key1];
        return Comparable.compare(
            a?.isEmpty ?? true ? double.negativeInfinity : a!.average,
            b?.isEmpty ?? true ? double.negativeInfinity : b!.average);
      });
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Consistency Analysis")),
      body: ListView(
        children: [
          DropdownButton<MatchResultsProcess>(
            value: _selectedProcess,
            onChanged: (MatchResultsProcess? value) {
              // This is called when the user selects an item.
              setState(() {
                _selectedProcess = value!;
              });
            },
            items: data.db.config.matchscouting.processes
                .map<DropdownMenuItem<MatchResultsProcess>>(
                    (MatchResultsProcess value) {
              return DropdownMenuItem<MatchResultsProcess>(
                value: value,
                child: Text(value.label),
              );
            }).toList(),
          ),
          if (teamValues == null) const Text("Select a process to see a plot"),
          if (valuesSorted != null)
            Row(children: [
              const SizedBox(width: 100, child: Center(child: Text("Team"))),
              Expanded(
                  child: CustomPaint(
                      painter: BoxPlotLabelPainter(
                          BoxPlot(values: [], min: min, max: max),
                          MediaQuery.of(context).size.height))),
              const SizedBox(width: 32),
            ]),
          if (valuesSorted != null)
            for (final entry in valuesSorted.entries)
              Row(children: [
                SizedBox(
                    width: 100,
                    child: TextButton(
                      child: Text(entry.key.toString()),
                      onPressed: () {
                        //Open this teams scouting page
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  TeamViewPage(teamNumber: entry.key)),
                        );
                      },
                    )),
                Expanded(
                    child: BoxPlot(max: max, min: min, values: entry.value)),
                const SizedBox(width: 32),
              ]),
        ],
      ),
    );
  }
}
