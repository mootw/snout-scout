import 'package:app/providers/data_provider.dart';
import 'package:app/helpers.dart';
import 'package:app/screens/teams_page.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:snout_db/config/surveyitem.dart';

class AnalysisPitScouting extends StatelessWidget {
  const AnalysisPitScouting({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text("Scouting Survey Analysis")),
      body: ListView(
        children: [
          Wrap(
            spacing: 42,
            runSpacing: 42,
            alignment: WrapAlignment.center,
            children: [
              for (final surveyItem in data.db.config.pitscouting
                  .where((element) => element.type != SurveyItemType.picture))
                SurveyItemRatioChart(surveyItem: surveyItem),
            ],
          ),
        ],
      ),
    );
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
    final data = context.watch<DataProvider>();

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
