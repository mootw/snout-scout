import 'package:app/widgets/datasheet.dart';
import 'package:app/helpers.dart';
import 'package:app/providers/data_provider.dart';
import 'package:app/screens/match_page.dart';
import 'package:app/screens/view_team_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:snout_db/config/surveyitem.dart';

class TableMatchRecordingsPage extends StatelessWidget {
  const TableMatchRecordingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        child: DataSheet(
          title: 'Match Recordings',
          //Data is a list of rows and columns
          columns: [
            DataItem.fromText("Match"),
            DataItem.fromText("Team"),
            for (final item in data.db.config.matchscouting.processes)
              DataItem.fromText(item.label),
            for (final item in data.db.config.matchscouting.survey)
              DataItem.fromText(item.label),
          ],
          rows: [
            for (final match in data.db.matches.entries.toList().reversed)
              for (final robot in match.value.robot.entries)
                [
                  DataItem(
                      displayValue: TextButton(
                          child: Text(match.value.description),
                          onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        MatchPage(matchid: match.key)),
                              )),
                      exportValue: match.value.description,
                      sortingValue: match.value),
                  DataItem(
                      displayValue: TextButton(
                          child: Text(robot.key,
                              style: TextStyle(
                                  color:
                                      getAllianceColor(robot.value.alliance))),
                          onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => TeamViewPage(
                                        teamNumber: int.parse(robot.key))),
                              )),
                      exportValue: robot.key,
                      sortingValue: robot.key),
                  for (final item in data.db.config.matchscouting.processes)
                    DataItem.fromNumber(data.db.runMatchResultsProcess(
                        item,
                        match.value.robot[robot.key],
                        int.tryParse(robot.key) ?? 0)),
                  for (final item in data.db.config.matchscouting.survey.where(
                      (element) => element.type != SurveyItemType.picture))
                    DataItem.fromText(match
                        .value.robot[robot.key]?.survey[item.id]
                        ?.toString()),
                ],
          ],
        ),
      ),
    );
  }
}