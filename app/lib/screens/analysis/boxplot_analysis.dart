import 'dart:collection';

import 'package:app/screens/analysis/boxplot.dart';
import 'package:app/providers/data_provider.dart';
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
    //Automatically select the first process by default if it exists (it might be null!)
    _selectedProcess = context.read<DataProvider>().event.config.matchscouting.processes.firstOrNull;
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();

    Map<int, List<num>>? teamValues;
    if (_selectedProcess != null) {
      teamValues = Map.fromEntries([
        for (final team in data.event.teams)
          MapEntry(team, [
            for (final match in data.event.teamRecordedMatches(team))
              data.event.runMatchResultsProcess(_selectedProcess!,
                      match.value.robot[team.toString()], team)?.value ??
                  0
          ])
      ]);
    }

    //Sort the numbers
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
      body: Column(
        children: [
          DropdownButton<MatchResultsProcess>(
            value: _selectedProcess,
            onChanged: (MatchResultsProcess? value) {
              // This is called when the user selects an item.
              setState(() {
                _selectedProcess = value!;
              });
            },
            items: data.event.config.matchscouting.processes
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
                          BoxPlot(values: const [], min: min, max: max),
                          MediaQuery.of(context).size.height))),
              const SizedBox(width: 32),
            ]),
          Expanded(
            child: ListView(
              children: [
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
                          child:
                              BoxPlot(max: max, min: min, values: entry.value)),
                      const SizedBox(width: 32),
                    ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
