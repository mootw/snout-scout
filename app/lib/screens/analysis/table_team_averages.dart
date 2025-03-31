import 'package:app/screens/analysis/match_preview.dart';
import 'package:app/providers/data_provider.dart';
import 'package:app/screens/view_team_page.dart';
import 'package:app/widgets/datasheet.dart';
import 'package:app/widgets/datasheet_full_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TableTeamAveragesPage extends StatelessWidget {
  const TableTeamAveragesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    return Scaffold(
      appBar: AppBar(),
      body: DataSheetFullScreen(
        title: 'Team Averages',
        columns: [
          DataItemColumn(DataItem.fromText("Team"), width: numericWidth),
          for (final item in data.event.config.matchscouting.processes)
            DataItemColumn(
              DataItem.fromText(item.label),
              largerIsBetter: item.isLargerBetter,
              width: numericWidth,
            ),
          for (final item in data.event.config.matchscouting.survey)
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
              for (final item in data.event.config.matchscouting.processes)
                DataItem.fromNumber(data.event.teamAverageProcess(team, item)),
              for (final item in data.event.config.matchscouting.survey)
                teamPostGameSurveyTableDisplay(data.event, team, item),
            ],
        ],
      ),
    );
  }
}
