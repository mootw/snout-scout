import 'package:flutter/material.dart';
import 'package:app/widgets/datasheet.dart';
import 'package:app/providers/data_provider.dart';
import 'package:provider/provider.dart';

class TableTeamDataItems extends StatelessWidget {
  const TableTeamDataItems({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    return Scaffold(
      appBar: AppBar(),
      body: DataSheet(
        title: 'Team Data Items',
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
