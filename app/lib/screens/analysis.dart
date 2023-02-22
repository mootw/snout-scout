import 'dart:math';

import 'package:app/fieldwidget.dart';
import 'package:app/helpers.dart';
import 'package:app/main.dart';
import 'package:app/screens/teams_page.dart';
import 'package:app/screens/view_team_page.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:snout_db/config/surveyitem.dart';

class AnalysisPage extends StatefulWidget {
  const AnalysisPage({Key? key}) : super(key: key);

  @override
  State<AnalysisPage> createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage> {
  @override
  Widget build(BuildContext context) {
    final data = context.watch<EventDB>();

    return ListView(shrinkWrap: true, children: [
      Wrap(
        spacing: 42,
        runSpacing: 42,
        alignment: WrapAlignment.center,
        children: [
          const Text(
              "Scoreboard (shows average value of all metrics for each team, like heatmaps) - Metrics Explorer - Match Predictor - Maybe allow for more 'sql' like queries here?? Performance comparison between two teams and their relative score when matched against each-other"),
          for (final surveyItem in data.db.config.pitscouting
              .where((element) => element.type != SurveyItemType.picture))
            SurveyItemRatioChart(surveyItem: surveyItem),
        ],
      ),


      Text("Autos", style: Theme.of(context).textTheme.titleLarge),
      FieldPaths(
        paths: [
          for (final match
              in data.db.matches.values)
              for(final robot in match.robot.entries)
                match.robot[robot.key]!
                    .timelineInterpolated
                    .where((element) => element.isInAuto)
                    .toList()
        ],
      ),


      for (final eventType
                    in data.db.config.matchscouting.events) ...[
                  const SizedBox(height: 16),
                  Text(eventType.label,
                      style: Theme.of(context).textTheme.titleLarge),
                  FieldHeatMap(
                      useRedNormalized: true,
                      events:
                          data.db.matches.values.fold(
                              [],
                              (previousValue, element) => [
                                    ...previousValue,
                                    ...element
                                        .robot.values.fold([], (previousValue, element) => [...previousValue, ...element.timeline
                                        .where(
                                            (event) => event.id == eventType.id)])
                    ])),
                ],

    ]);
  }
}

class SurveyItemRatioChart extends StatefulWidget {
  const SurveyItemRatioChart({super.key, required this.surveyItem});

  final SurveyItem surveyItem;

  @override
  State<SurveyItemRatioChart> createState() => _SurveyItemRatioChartState();
}

class _SurveyItemRatioChartState extends State<SurveyItemRatioChart> {
  int _selectedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final data = context.watch<EventDB>();

    //Map of all of the values, to their respective teams
    Map<String, List<String>> valueKeys = {};

    for (final team in data.db.pitscouting.keys) {
      final item = data.db.pitscouting[team]![widget.surveyItem.id]?.toString();
      if (item == null) {
        //TODO handle NULL items in their own category??
        //Basically this is just missing data in the chart.
        continue;
      }
      if (valueKeys[item] == null) {
        valueKeys[item] = [team];
      } else {
        valueKeys[item]!.add(team);
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(widget.surveyItem.label,
            style: Theme.of(context).textTheme.titleMedium),
        SizedBox(
          height: 250,
          width: 250,
          child: PieChart(PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  setState(() {
                    if (!event.isInterestedForInteractions ||
                        pieTouchResponse == null ||
                        pieTouchResponse.touchedSection == null) {
                      _selectedIndex = -1;
                      return;
                    }
                    _selectedIndex =
                        pieTouchResponse.touchedSection!.touchedSectionIndex;

                    if (event is FlTapUpEvent && _selectedIndex != -1) {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => Scaffold(
                              appBar: AppBar(
                                  title: Text(
                                      '${widget.surveyItem.label}: ${valueKeys.entries.toList()[_selectedIndex].key}')),
                              body: TeamGridList(
                                  teamFiler: valueKeys.entries
                                      .toList()[_selectedIndex]
                                      .value
                                      .map((e) => int.parse(e))
                                      .toList()),
                            ),
                          ));
                    }
                  });
                },
              ),
              sections: [
                for (int i = 0; i < valueKeys.entries.length; i++)
                  PieChartSectionData(
                    radius: _selectedIndex == i ? 45 : 40,
                    title: valueKeys.entries.toList()[i].key,
                    value:
                        valueKeys.entries.toList()[i].value.length.toDouble(),
                    color: getColorFromIndex(i),
                  ),
              ])),
        ),
      ],
    );
  }
}
