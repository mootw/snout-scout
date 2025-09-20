import 'package:flutter/material.dart';
import 'package:app/widgets/datasheet.dart';
import 'package:app/providers/data_provider.dart';
import 'package:app/screens/view_team_page.dart';
import 'package:provider/provider.dart';

class TableTeamSurvey extends StatelessWidget {
  const TableTeamSurvey({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    return Scaffold(
      appBar: AppBar(),
      body: DataSheet(
        title: 'Team Survey',
        columns: [
          DataItemColumn(DataItem.fromText("Team"), width: numericWidth),
          for (final item in data.event.config.pitscouting)
            DataItemColumn.fromSurveyItem(item),
        ],
        rows: [
          for (final team in data.event.teams)
            [
              DataItem(
                displayValue: TextButton(
                  child: Text(team.toString()),
                  onPressed:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TeamViewPage(teamNumber: team),
                        ),
                      ),
                ),
                exportValue: team.toString(),
                sortingValue: team,
              ),
              for (final surveyItem in data.event.config.pitscouting)
                DataItem.fromSurveyItem(
                  data.event.pitscouting[team.toString()]?[surveyItem.id],
                  surveyItem,
                ),
            ],
        ],
      ),
    );
  }
}
