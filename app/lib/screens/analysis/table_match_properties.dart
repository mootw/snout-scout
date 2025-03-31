import 'package:app/widgets/datasheet.dart';
import 'package:app/providers/data_provider.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TableMatchProperties extends StatelessWidget {
  const TableMatchProperties({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();

    final allMatchIds = {
      ...data.event.schedule.keys,
      ...data.event.matches.keys,
    };

    // TODO this method is used in 2 places and does not correctly sort mixed scheduled and recorded (but missing schedule) matches
    final allMatchData = {
      for (final matchId in allMatchIds)
        (data.event.schedule[matchId], data.event.matches[matchId], matchId),
    }..sorted(
      (a, b) => a.$1 == null || b.$1 == null ? 0 : a.$1?.compareTo(b.$1!) ?? 0,
    );

    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        child: DataSheet(
          title: 'Match Data',
          //Data is a list of rows and columns
          columns: [
            DataItemColumn(DataItem.fromText("Match")),
            for (final item in data.event.config.matchscouting.properties)
              DataItemColumn(DataItem.fromText(item.label)),
          ],
          rows: [
            for (final match in allMatchData)
              [
                DataItem.match(
                  context: context,
                  key: match.$3,
                  label: match.$1?.label ?? match.$3,
                  time: match.$1?.scheduledTime,
                ),
                for (final item in data.event.config.matchscouting.properties)
                  DataItem.fromSurveyItem(match.$2?.properties?[item.id], item),
              ],
          ],
        ),
      ),
    );
  }
}
