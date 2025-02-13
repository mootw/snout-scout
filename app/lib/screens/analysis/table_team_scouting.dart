import 'package:flutter/material.dart';
import 'package:app/widgets/datasheet.dart';
import 'package:app/providers/data_provider.dart';
import 'package:app/screens/view_team_page.dart';
import 'package:provider/provider.dart';

class TableTeamPitSurvey extends StatelessWidget {
  const TableTeamPitSurvey({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        child: DataSheet(title: 'Team Survey', columns: [
          DataItem.fromText("Team"),
          for (final pitSurvey in data.event.config.pitscouting)
            DataItem.fromText(pitSurvey.label),
        ], rows: [
          for (final team in data.event.teams)
            [
              DataItem(
                  displayValue: TextButton(
                      child: Text(team.toString()),
                      onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    TeamViewPage(teamNumber: team)),
                          )),
                  exportValue: team.toString(),
                  sortingValue: team),
              for (final surveyItem in data.event.config.pitscouting)
                DataItem.fromSurveyItem(
                    team,
                    data.event.pitscouting[team.toString()]?[surveyItem.id],
                    surveyItem)
            ]
        ]),
      ),
    );
  }
}
