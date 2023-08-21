


import 'package:app/widgets/datasheet.dart';
import 'package:app/providers/data_provider.dart';
import 'package:app/screens/view_team_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:snout_db/config/surveyitem.dart';

class TableTeamAveragesPage extends StatelessWidget {
  const TableTeamAveragesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        child: DataSheet(title: 'Team Averages', columns: [
              DataItem.fromText("Team"),
              for (final item in data.db.config.matchscouting.processes)
                DataItem.fromText(item.label),
              for (final pitSurvey in data.db.config.pitscouting
                  .where((element) => element.type != SurveyItemType.picture))
                DataItem.fromText(pitSurvey.label),
            ], rows: [
              for (final team in data.db.teams)
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
                  for (final item in data.db.config.matchscouting.processes)
                    DataItem.fromNumber(data.db.teamAverageProcess(team, item)),
                  for (final pitSurvey in data.db.config.pitscouting
                      .where((element) => element.type != SurveyItemType.picture))
                    DataItem.fromText(data
                        .db.pitscouting[team.toString()]?[pitSurvey.id]
                        ?.toString())
                ]
            ]),
      ),
    );
  }
}