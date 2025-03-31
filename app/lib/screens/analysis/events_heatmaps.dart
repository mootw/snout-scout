import 'package:app/providers/data_provider.dart';
import 'package:app/widgets/fieldwidget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AnalysisEventsHeatmap extends StatelessWidget {
  const AnalysisEventsHeatmap({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text("Events Heatmap Analysis"),
      ),
      body: ListView(children: [
        Center(
            child: Text("Auto Paths",
                style: Theme.of(context).textTheme.titleMedium)),
        Center(
          child: PathsViewer(
            paths: [
              for (final match in data.event.matches.entries)
                for (final robot in match.value.robot.entries)
                  (
                    label:
                        '${match.value.getSchedule(data.event, match.key)?.label} ${robot.key}',
                    path: match.value.robot[robot.key]!.timelineInterpolated
                        .where((element) => element.isInAuto)
                        .toList()
                  )
            ],
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text("Autos Heatmap",
              style: Theme.of(context).textTheme.titleMedium),
        ),
        Center(
          child: FieldHeatMap(size: largeFieldSize, events: [
            for (final match in data.event.matches.values)
              for (final robot in match.robot.values)
                ...robot
                    .timelineInterpolatedBlueNormalized(
                        data.event.config.fieldStyle)
                    .where((event) => event.isInAuto)
          ]),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text("Ending Positions",
              style: Theme.of(context).textTheme.titleMedium),
        ),
        Center(
            child: FieldHeatMap(
                size: largeFieldSize,
                events: [
                  for (final match in data.event.matches.values)
                    for (final robot in match.robot.values)
                      robot
                          .timelineInterpolatedBlueNormalized(
                              data.event.config.fieldStyle)
                          .where((event) => event.isPositionEvent)
                          .lastOrNull
                ].nonNulls.toList())),
        for (final eventType in data.event.config.matchscouting.events) ...[
          const SizedBox(height: 16),
          Center(
            child: Text(eventType.label,
                style: Theme.of(context).textTheme.titleMedium),
          ),
          Center(
              child: FieldHeatMap(size: largeFieldSize, events: [
            for (final match in data.event.matches.values)
              for (final robot in match.robot.values)
                ...robot
                    .timelineBlueNormalized(data.event.config.fieldStyle)
                    .where((event) => event.id == eventType.id)
          ]))
        ]
      ]),
    );
  }
}
