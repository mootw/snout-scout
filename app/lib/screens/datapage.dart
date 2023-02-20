import 'package:app/datasheet.dart';
import 'package:app/main.dart';
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
    final data = context.watch<EventDB>();
    return SingleChildScrollView(
      child: DataSheet(columns: [
        DataItem.fromText("Team"),
        DataItem.fromText("Played"),
        for (final eventType in data.db.config.matchscouting.events)
          DataItem.fromText("Avg:\n${eventType.label}"),
        for (final pitSurvey in data.db.config.pitscouting
            .where((element) => element.type != SurveyItemType.picture))
          DataItem.fromText(pitSurvey.label),
      ], rows: [
        for (final team in data.db.teams)
          [
            DataItem(
                displayValue: TextButton(
                  child: Text(team.toString()),
                  onPressed: () {
                    //Open this teams scouting page
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => TeamViewPage(teamNumber: team)),
                    );
                  },
                ),
                exportValue: team.toString(),
                sortingValue: team),
            DataItem.fromNumber(data.db
                .matchesWithTeam(team)
                .where((element) => element.results != null)
                .length
                .toDouble()),
            for (final eventType in data.db.config.matchscouting.events)
              DataItem.fromNumber(data.db.matchesWithTeam(team).fold<int>(
                      0,
                      (previousValue, match) =>
                          previousValue +
                          (match.robot[team.toString()]?.timeline
                                  .where((event) => event.id == eventType.id)
                                  .length ??
                              0)) /
                  data.db
                      .matchesWithTeam(team)
                      .where(
                          (element) => element.robot[team.toString()] != null)
                      .length),
            for (final pitSurvey in data.db.config.pitscouting
                .where((element) => element.type != SurveyItemType.picture))
              DataItem.fromText(data
                      .db.pitscouting[team.toString()]?[pitSurvey.id]
                      ?.toString())
          ]
      ]),
    );
  }
}
