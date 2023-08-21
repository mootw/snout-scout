import 'package:app/providers/data_provider.dart';
import 'package:app/helpers.dart';
import 'package:app/screens/teams_page.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:snout_db/config/surveyitem.dart';

class AnalysisPostMatchSurvey extends StatelessWidget {
  const AnalysisPostMatchSurvey({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text("Post-Match Survey Analysis")),
      body: ListView(
        children: [
          Wrap(
            spacing: 42,
            runSpacing: 42,
            alignment: WrapAlignment.center,
            children: [
              for (final surveyItem in data.db.config.matchscouting.survey
                  .where((element) => element.type != SurveyItemType.picture))
                PostGameRatioChart(surveyItem: surveyItem),
            ],
          ),
        ],
      ),
    );
  }
}

class PostGameRatioChart extends StatefulWidget {
  const PostGameRatioChart({super.key, required this.surveyItem});

  final SurveyItem surveyItem;

  @override
  State<PostGameRatioChart> createState() => _PostGameRatioChartState();
}

class _PostGameRatioChartState extends State<PostGameRatioChart> {
  int _selectedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();

    //Map of all of the values, to their respective teams
    Map<String, Map<String, dynamic>> valueKeys = {};

    for (final match in data.db.matches.values) {
      for (final robot in match.robot.entries) {
        final item = robot.value.survey[widget.surveyItem.id]?.toString();
        if (item == null) {
          //Basically this is just missing data in the chart.
          continue;
        }
        if (valueKeys[item] == null) {
          valueKeys[item] = {
            "count": 1,
            "teams": [robot.key]
          };
        } else {
          valueKeys[item]!['count']++;
          valueKeys[item]!['teams'].add(robot.key);
        }
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
                    _selectedIndex =
                        pieTouchResponse?.touchedSection?.touchedSectionIndex ??
                            _selectedIndex;

                    if (event is FlTapUpEvent && _selectedIndex != -1) {
                      //TODO this is so incredibly jank there is a weird timing issue where it gets modified randomly...
                      int asdf = _selectedIndex;
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => Scaffold(
                              appBar: AppBar(
                                  title: Text(
                                      '${widget.surveyItem.label}:  ${valueKeys.entries.toList()[asdf].key}')),
                              body: TeamGridList(
                                  teamFiler: valueKeys.entries
                                      .toList()[asdf]
                                      .value['teams']
                                      .map<int>((e) => int.parse(e))
                                      .toList()),
                            ),
                          ));
                    }
                    if (!event.isInterestedForInteractions ||
                        pieTouchResponse == null ||
                        pieTouchResponse.touchedSection == null) {
                      _selectedIndex = -1;
                      return;
                    }
                  });
                },
              ),
              sections: [
                for (int i = 0; i < valueKeys.entries.length; i++)
                  PieChartSectionData(
                    // radius: _selectedIndex == i ? 45 : 40,
                    radius: 40,
                    title: valueKeys.entries.toList()[i].key,
                    value:
                        valueKeys.entries.toList()[i].value['count'].toDouble(),
                    color: getColorFromIndex(i),
                  ),
              ])),
        ),
      ],
    );
  }
}
