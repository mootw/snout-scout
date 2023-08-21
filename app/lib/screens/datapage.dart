import 'package:app/datasheet.dart';
import 'package:app/providers/data_provider.dart';
import 'package:app/helpers.dart';
import 'package:app/screens/match_page.dart';
import 'package:app/screens/view_team_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:snout_db/config/surveyitem.dart';

class DataTablePage extends StatefulWidget {
  const DataTablePage({super.key});

  @override
  State<DataTablePage> createState() => _DataTablePageState();
}

class _DataTablePageState extends State<DataTablePage> {
  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    return ListView(
      cacheExtent: 5000,
      children: [
        DataSheet(title: 'Team Averages', columns: [
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
        DataSheet(
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
      ],
    );
  }
}
