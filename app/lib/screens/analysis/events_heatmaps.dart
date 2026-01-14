import 'package:app/providers/data_provider.dart';
import 'package:app/widgets/fieldwidget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:snout_db/config/match_period_config.dart';

class AnalysisEventsHeatmap extends StatelessWidget {
  const AnalysisEventsHeatmap({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text("Events Heatmap Analysis")),
      body: ListView(
        primary: true,
        children: [
          Center(
            child: Text(
              "Auto Paths",
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Center(
            child: PathsViewer(
              paths: [
                for (final match in data.event.matches.entries)
                  for (final robot in match.value.robot.entries)
                    (
                      label:
                          '${match.value.getSchedule(data.event, match.key)?.label} ${robot.key}',
                      path: match.value.robot[robot.key]!.timelineInterpolated
                          .where(
                            (element) =>
                                data.event.config
                                    .getPeriodAtTime(element.timeDuration)
                                    .id ==
                                autoPeriodId,
                          )
                          .toList(),
                    ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              "Driving Area",
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Center(
            child: FieldHeatMap(
              size: largeFieldSize,
              events: [
                for (final match in data.event.matches.entries)
                  for (final robot in match.value.robot.entries)
                    ...match.value.robot[robot.key]!
                        .timelineInterpolatedBlueNormalized(
                          data.event.config.fieldStyle,
                        )
                        .where((element) => element.isPositionEvent),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              "Autos Heatmap",
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Center(
            child: FieldHeatMap(
              size: largeFieldSize,
              events: [
                for (final match in data.event.matches.values)
                  for (final robot in match.robot.values)
                    ...robot
                        .timelineInterpolatedBlueNormalized(
                          data.event.config.fieldStyle,
                        )
                        .where(
                          (event) =>
                              data.event.config
                                  .getPeriodAtTime(event.timeDuration)
                                  .id ==
                              autoPeriodId,
                        ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              "Ending Positions",
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Center(
            child: FieldHeatMap(
              size: largeFieldSize,
              events: [
                for (final match in data.event.matches.values)
                  for (final robot in match.robot.values)
                    robot
                        .timelineInterpolatedBlueNormalized(
                          data.event.config.fieldStyle,
                        )
                        .where((event) => event.isPositionEvent)
                        .lastOrNull,
              ].nonNulls.toList(),
            ),
          ),
          for (final eventType in data.event.config.matchscouting.events) ...[
            const SizedBox(height: 16),
            Center(
              child: Text(
                eventType.label,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Center(
              child: FieldHeatMap(
                size: largeFieldSize,
                events: [
                  for (final match in data.event.matches.values)
                    for (final robot in match.robot.values)
                      ...robot
                          .timelineBlueNormalized(data.event.config.fieldStyle)
                          .where((event) => event.id == eventType.id),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
