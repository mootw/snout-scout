import 'package:app/widgets/datasheet.dart';
import 'package:app/style.dart';
import 'package:app/providers/data_provider.dart';
import 'package:app/screens/view_team_page.dart';
import 'package:app/widgets/datasheet_full_screen.dart';
import 'package:app/widgets/edit_audit.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:snout_db/patch.dart';

class TableRobotRecordingsPage extends StatelessWidget {
  const TableRobotRecordingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    return Scaffold(
      appBar: AppBar(),
      body: DataSheetFullScreen(
        numFixedColumns: 2,
        title: 'Robot Recordings',
        //Data is a list of rows and columns
        columns: [
          DataItemColumn(DataItem.fromText("Match")),
          DataItemColumn(DataItem.fromText("Team"), width: numericWidth),
          for (final item in data.event.config.matchscouting.processes)
            DataItemColumn(
              DataItem.fromText(item.label),
              largerIsBetter: item.isLargerBetter,
              width: numericWidth,
            ),
          for (final item in data.event.config.matchscouting.survey)
            DataItemColumn.fromSurveyItem(item),
          DataItemColumn(DataItem.fromText("Scout")),
        ],
        rows: [
          for (final match in data.event.matchesSorted().reversed)
            for (final robot in match.value.robot.entries)
              [
                DataItem.match(
                  context: context,
                  key: match.key,
                  label:
                      match.value.getSchedule(data.event, match.key)?.label ??
                      match.key,
                  time:
                      match.value
                          .getSchedule(data.event, match.key)
                          ?.scheduledTime,
                ),
                DataItem(
                  displayValue: TextButton(
                    child: Text(
                      robot.key,
                      style: TextStyle(
                        color: getAllianceUIColor(robot.value.alliance),
                      ),
                    ),
                    onPressed:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => TeamViewPage(
                                  teamNumber: int.parse(robot.key),
                                ),
                          ),
                        ),
                  ),
                  exportValue: robot.key,
                  sortingValue: robot.key,
                ),
                for (final item in data.event.config.matchscouting.processes)
                  DataItem.fromErrorNumber(
                    data.event.runMatchResultsProcess(
                          item,
                          match.value.robot[robot.key],
                          int.tryParse(robot.key) ?? 0,
                        ) ??
                        (value: null, error: "Missing Results"),
                  ),
                for (final item in data.event.config.matchscouting.survey)
                  DataItem.fromSurveyItem(
                    match.value.robot[robot.key]?.survey[item.id],
                    item,
                  ),
                DataItem.fromText(
                  getAuditString(
                    context.watch<DataProvider>().database.getLastPatchFor(
                      Patch.buildPath([
                        'matches',
                        match.key,
                        'robot',
                        robot.key,
                      ]),
                    ),
                  ),
                ),
              ],
        ],
      ),
    );
  }
}
