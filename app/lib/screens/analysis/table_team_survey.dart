import 'package:app/widgets/team_avatar.dart';
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
          DataItemColumn.teamHeader(),
          for (final item in data.event.config.pitscouting)
            DataItemColumn.fromSurveyItem(item),
        ],
        rows: [
          for (final team in data.event.teams)
            [
              DataTableItem.fromTeam(context: context, team: team),
              for (final surveyItem in data.event.config.pitscouting)
                DataTableItem.fromSurveyItem(
                  data.event.pitscouting[team.toString()]?[surveyItem.id],
                  surveyItem,
                ),
            ],
        ],
      ),
    );
  }
}
