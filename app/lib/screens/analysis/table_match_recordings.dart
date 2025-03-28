import 'package:app/widgets/datasheet.dart';
import 'package:app/style.dart';
import 'package:app/providers/data_provider.dart';
import 'package:app/screens/view_team_page.dart';
import 'package:app/widgets/edit_audit.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:snout_db/patch.dart';

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
            for (final item in data.event.config.matchscouting.processes)
              DataItem.fromText(item.label),
            for (final item in data.event.config.matchscouting.survey)
              DataItem.fromText(item.label),
            DataItem.fromText("Scout")
          ],
          rows: [
            for (final match in data.event.matches.entries.toList().reversed)
              for (final robot in match.value.robot.entries)
                [
                  DataItem.match(
                      context: context,
                      key: match.key,
                      description: match.value.description,
                      time: match.value.scheduledTime),
                  DataItem(
                      displayValue: TextButton(
                          child: Text(robot.key,
                              style: TextStyle(
                                  color: getAllianceUIColor(
                                      robot.value.alliance))),
                          onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => TeamViewPage(
                                        teamNumber: int.parse(robot.key))),
                              )),
                      exportValue: robot.key,
                      sortingValue: robot.key),
                  for (final item in data.event.config.matchscouting.processes)
                    DataItem.fromErrorNumber(data.event.runMatchResultsProcess(
                            item,
                            match.value.robot[robot.key],
                            int.tryParse(robot.key) ?? 0) ??
                        (value: null, error: "Missing Results")),
                  for (final item in data.event.config.matchscouting.survey)
                    DataItem.fromSurveyItem(
                        match.value.robot[robot.key]?.survey[item.id], item),
                  DataItem.fromText(getAuditString(context
                      .watch<DataProvider>()
                      .database
                      .getLastPatchFor(Patch.buildPath(
                          ['matches', match.key, 'robot', robot.key])))),
                ],
          ],
        ),
      ),
    );
  }
}
