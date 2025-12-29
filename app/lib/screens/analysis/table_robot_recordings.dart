import 'package:app/widgets/datasheet.dart';
import 'package:app/style.dart';
import 'package:app/providers/data_provider.dart';
import 'package:app/screens/view_team_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TableRobotRecordingsPage extends StatelessWidget {
  const TableRobotRecordingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    return Scaffold(
      appBar: AppBar(),
      body: DataSheet(
        numFixedColumns: 2,
        title: 'Robot Traces',
        //Data is a list of rows and columns
        columns: [
          DataItemColumn.matchHeader(),
          DataItemColumn.teamHeader(),
          for (final item in data.event.config.matchscouting.processes)
            DataItemColumn.fromProcess(item),
          for (final item in data.event.config.matchscouting.survey)
            DataItemColumn.fromSurveyItem(item),
        ],
        rows: [
          for (final match in data.event.matchesSorted().reversed)
            for (final robot in match.value.robot.entries)
              [
                DataTableItem.fromMatch(
                  context: context,
                  key: match.key,
                  label:
                      match.value.getSchedule(data.event, match.key)?.label ??
                      match.key,
                  time: match.value
                      .getSchedule(data.event, match.key)
                      ?.scheduledTime,
                ),
                DataTableItem(
                  displayValue: TextButton(
                    child: Text(
                      robot.key,
                      style: TextStyle(
                        color: getAllianceUIColor(robot.value.alliance),
                      ),
                    ),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            TeamViewPage(teamNumber: int.parse(robot.key)),
                      ),
                    ),
                  ),
                  exportValue: robot.key,
                  sortingValue: robot.key,
                ),
                for (final item in data.event.config.matchscouting.processes)
                  DataTableItem.fromErrorNumber(
                    data.event.runMatchResultsProcess(
                          item,
                          match.value.robot[robot.key],
                          data.event.matchSurvey(int.tryParse(robot.key) ?? 0, match.key),
                          int.tryParse(robot.key) ?? 0,
                        ) ??
                        (value: null, error: "Missing Results"),
                  ),
                for (final item in data.event.config.matchscouting.survey)
                  DataTableItem.fromSurveyItem(
                    data.event.matchSurvey(
                      int.tryParse(robot.key) ?? 0,
                      match.key,
                    )?[item.id],
                    item,
                  ),
              ],
        ],
      ),
    );
  }
}
