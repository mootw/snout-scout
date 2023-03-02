import 'package:app/fieldwidget.dart';
import 'package:app/main.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AnalysisEventsHeatmap extends StatelessWidget {
  const AnalysisEventsHeatmap({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<EventDB>();
    return Scaffold(
      appBar: AppBar(
        title: const Text("Events Heatmap Analysis"),
      ),
      body: ListView(
        children: [
          Text("Autos", style: Theme.of(context).textTheme.titleMedium),
          FieldPaths(
            paths: [
              for (final match in data.db.matches.values)
                for (final robot in match.robot.entries)
                  match.robot[robot.key]!.timelineInterpolated
                      .where((element) => element.isInAuto)
                      .toList()
            ],
          ),
          for (final eventType in data.db.config.matchscouting.events) ...[
            const SizedBox(height: 16),
            Text(eventType.label,
                style: Theme.of(context).textTheme.titleMedium),
            FieldHeatMap(
                events: data.db.matches.values.fold(
                    [],
                    (previousValue, element) => [
                          ...previousValue,
                          ...element.robot.values.fold(
                              [],
                              (previousValue, element) => [
                                    ...previousValue,
                                    ...element.timeline.where(
                                        (event) => event.id == eventType.id)
                                  ])
                        ])),
          ],
          const SizedBox(height: 16),
          Text("Driving Tendencies",
              style: Theme.of(context).textTheme.titleMedium),
          FieldHeatMap(
              events: data.db.matches.values.fold(
                  [],
                  (previousValue, element) => [
                        ...previousValue,
                        ...?element.robot.entries.fold(
                            [],
                            (previousValue, element) => [
                                  ...previousValue!,
                                  ...element.value.timelineInterpolated.where(
                                      (event) => event.isPositionEvent)
                                ])
                      ])),
        ],
      ),
    );
  }
}
