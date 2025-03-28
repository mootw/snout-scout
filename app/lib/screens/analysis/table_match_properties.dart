import 'package:app/widgets/datasheet.dart';
import 'package:app/providers/data_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TableMatchProperties extends StatelessWidget {
  const TableMatchProperties({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        child: DataSheet(
          title: 'Match Data',
          //Data is a list of rows and columns
          columns: [
            DataItem.fromText("Match"),
            for (final item in data.event.config.matchscouting.properties)
              DataItem.fromText(item.label),
          ],
          rows: [
            for (final match in data.event.matches.entries)
              [
                DataItem.match(
                    context: context,
                    key: match.key,
                    description: match.value.description,
                    time: match.value.scheduledTime),
                for (final item in data.event.config.matchscouting.properties)
                  DataItem.fromSurveyItem(
                      match.value.properties![item.id], item),
              ],
          ],
        ),
      ),
    );
  }
}
