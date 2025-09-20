import 'package:app/services/snout_image_cache.dart';
import 'package:app/widgets/datasheet.dart';
import 'package:app/edit_lock.dart';
import 'package:app/providers/data_provider.dart';
import 'package:app/widgets/edit_audit.dart';
import 'package:app/widgets/fieldwidget.dart';
import 'package:app/style.dart';
import 'package:app/screens/match_page.dart';
import 'package:app/screens/scout_team.dart';
import 'package:app/widgets/image_view.dart';
import 'package:app/widgets/timeduration.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:snout_db/config/surveyitem.dart';
import 'package:snout_db/event/match_schedule_item.dart';
import 'package:snout_db/patch.dart';

// Reserved pit scouting IDs that are used within the app
const String teamNameReserved = 'team_name';
const String robotPictureReserved = 'robot_picture';
const String teamNotesReserved = 'team_notes';

class TeamViewPage extends StatefulWidget {
  final int teamNumber;

  const TeamViewPage({super.key, required this.teamNumber});

  @override
  State<TeamViewPage> createState() => _TeamViewPageState();
}

class _TeamViewPageState extends State<TeamViewPage> {
  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();

    String? teamName =
        data.event.pitscouting[widget.teamNumber.toString()]?[teamNameReserved];
    String? robotPicture =
        data.event.pitscouting[widget.teamNumber
            .toString()]?[robotPictureReserved];
    String? teamNotes =
        data.event.pitscouting[widget.teamNumber
            .toString()]?[teamNotesReserved];

    MatchScheduleItem? teamNextMatch = data.event.nextMatchForTeam(
      widget.teamNumber,
    );
    Duration? scheduleDelay = data.event.scheduleDelay;

    final matchIds = {
      ...data.event.matchesWithTeam(widget.teamNumber).map((e) => e.id),
      ...data.event.teamRecordedMatches(widget.teamNumber).map((e) => e.key),
    };

    return Scaffold(
      appBar: AppBar(
        actions: [
          TextButton(
            onPressed: () async {
              await navigateWithEditLock(
                context,
                "scoutteam:${widget.teamNumber}",
                (context) => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (_) => EditTeamPage(
                          team: widget.teamNumber,
                          config: data.event.config.pitscouting,
                          initialData:
                              data.event.pitscouting[widget.teamNumber
                                  .toString()],
                        ),
                  ),
                ),
              );
            },
            child: const Text("Scout"),
          ),
        ],
        title: Text(
          "Team ${widget.teamNumber}${teamName == null ? '' : ': $teamName'}",
        ),
      ),
      body: ListView(
        cacheExtent: 5000,
        children: [
          Row(
            children: [
              if (robotPicture != null)
                SizedBox(
                  width: 240,
                  height: 240,
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: ImageViewer(
                      child: Image(
                        image: snoutImageCache.getCached(robotPicture),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              if (robotPicture == null)
                const Text("No $robotPictureReserved :("),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(teamNotes ?? "No $teamNotesReserved value"),
                    ],
                  ),
                ),
              ),
            ],
          ),
          teamNextMatch != null && scheduleDelay != null
              ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("next match"),
                  TextButton(
                    onPressed:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) =>
                                    MatchPage(matchid: teamNextMatch.id),
                          ),
                        ),
                    child: Text(
                      teamNextMatch.label,
                      style: TextStyle(
                        color: getAllianceUIColor(
                          teamNextMatch.getAllianceOf(widget.teamNumber),
                        ),
                      ),
                    ),
                  ),
                  TimeDuration(
                    time: teamNextMatch.scheduledTime.add(scheduleDelay),
                    displayDurationDefault: true,
                  ),
                ],
              )
              : const Center(child: Text('No upcoming matches')),
          const Divider(),
          DataSheet(
            shrinkWrap: true,
            title: 'Matches',
            //Data is a list of rows and columns
            columns: [
              DataItemColumn.matchHeader(),
              for (final item in data.event.config.matchscouting.processes)
                DataItemColumn.fromProcess(item),
              for (final pitSurvey in data.event.config.matchscouting.survey)
                DataItemColumn.fromSurveyItem(pitSurvey),
              DataItemColumn(DataItem.fromText("Scout")),
            ],
            rows: [
              //Show ALL matches the team is scheduled for ALONG with all matches they played regardless of it it is scheduled sorted
              for (final match in {
                for (final matchId in matchIds)
                  (
                    data.event.schedule[matchId],
                    data.event.matches[matchId],
                    matchId,
                  ),
              }.sorted(
                (a, b) =>
                    a.$1 == null || b.$1 == null
                        ? 0
                        : a.$1?.compareTo(b.$1!) ?? 0,
              ))
                [
                  DataItem.fromMatch(
                    context: context,
                    label: match.$1?.label ?? match.$3,
                    key: match.$3,
                    time: match.$1?.scheduledTime,
                    color:
                        getAllianceUIColor(
                          match
                              .$2
                              ?.robot[widget.teamNumber.toString()]
                              ?.alliance,
                        ) ??
                        getAllianceUIColor(
                          match.$1?.getAllianceOf(widget.teamNumber),
                        ),
                  ),
                  for (final item in data.event.config.matchscouting.processes)
                    DataItem.fromErrorNumber(
                      data.event.runMatchResultsProcess(
                            item,
                            match.$2?.robot[widget.teamNumber.toString()],
                            widget.teamNumber,
                          ) ??
                          (value: null, error: null),
                    ),
                  for (final pitSurvey
                      in data.event.config.matchscouting.survey)
                    DataItem.fromSurveyItem(
                      match
                          .$2
                          ?.robot[widget.teamNumber.toString()]
                          ?.survey[pitSurvey.id],
                      pitSurvey,
                    ),
                  DataItem.fromText(
                    getAuditString(
                      context.watch<DataProvider>().database.getLastPatchFor(
                        Patch.buildPath([
                          'matches',
                          match.$3,
                          'robot',
                          '${widget.teamNumber}',
                        ]),
                      ),
                    ),
                  ),
                ],
            ],
          ),
          const Divider(),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            alignment: WrapAlignment.center,
            children: [
              Text("Autos", style: Theme.of(context).textTheme.titleMedium),
              PathsViewer(
                size: 600,
                paths: [
                  for (final match in data.event.teamRecordedMatches(
                    widget.teamNumber,
                  ))
                    (
                      label:
                          match.value
                              .getSchedule(data.event, match.key)
                              ?.label ??
                          match.key,
                      path:
                          match.value.robot[widget.teamNumber.toString()]!
                              .timelineInterpolatedBlueNormalized(
                                data.event.config.fieldStyle,
                              )
                              .where((element) => element.isInAuto)
                              .toList(),
                    ),
                ],
              ),
              Column(
                children: [
                  const SizedBox(height: 16),
                  Text(
                    "Autos Heatmap",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  FieldHeatMap(
                    events: [
                      for (final match in data.event.teamRecordedMatches(
                        widget.teamNumber,
                      ))
                        ...match.value.robot[widget.teamNumber.toString()]!
                            .timelineInterpolatedBlueNormalized(
                              data.event.config.fieldStyle,
                            )
                            .where((element) => element.isInAuto),
                    ],
                  ),
                ],
              ),
              const Divider(height: 32),
              DataSheet(
                shrinkWrap: true,
                title: 'Metrics',
                //Data is a list of rows and columns
                columns: [
                  DataItemColumn(DataItem.fromText("Metric")),
                  for (final event in data.event.config.matchscouting.events)
                    DataItemColumn(
                      DataItem.fromText(event.label),
                      largerIsBetter: event.isLargerBetter,
                    ),
                ],
                rows: [
                  [
                    DataItem.fromText("Total"),
                    for (final event in data.event.config.matchscouting.events)
                      DataItem.fromNumber(
                        data.event.teamAverageMetric(
                          widget.teamNumber,
                          event.id,
                        ),
                      ),
                  ],
                  [
                    DataItem.fromText("Auto"),
                    for (final eventType
                        in data.event.config.matchscouting.events)
                      DataItem.fromNumber(
                        data.event.teamAverageMetric(
                          widget.teamNumber,
                          eventType.id,
                          (event) => event.isInAuto,
                        ),
                      ),
                  ],
                  [
                    DataItem.fromText("Teleop"),
                    for (final eventType
                        in data.event.config.matchscouting.events)
                      DataItem.fromNumber(
                        data.event.teamAverageMetric(
                          widget.teamNumber,
                          eventType.id,
                          (event) => !event.isInAuto,
                        ),
                      ),
                  ],
                ],
              ),
              const Divider(),
              Column(
                children: [
                  const SizedBox(height: 16),
                  Text(
                    "Starting Positions",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  FieldHeatMap(
                    events:
                        [
                          for (final match in data.event.teamRecordedMatches(
                            widget.teamNumber,
                          ))
                            match.value.robot[widget.teamNumber.toString()]!
                                .timelineInterpolatedBlueNormalized(
                                  data.event.config.fieldStyle,
                                )
                                .where((element) => element.isPositionEvent)
                                .firstOrNull,
                        ].nonNulls.toList(),
                  ),
                ],
              ),
              for (final eventType in data.event.config.matchscouting.events)
                Column(
                  children: [
                    const SizedBox(height: 16),
                    Text(
                      eventType.label,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    FieldHeatMap(
                      events: [
                        for (final match in data.event.teamRecordedMatches(
                          widget.teamNumber,
                        ))
                          ...?match.value.robot[widget.teamNumber.toString()]
                              ?.timelineBlueNormalized(
                                data.event.config.fieldStyle,
                              )
                              .where((event) => event.id == eventType.id),
                      ],
                    ),
                  ],
                ),
              Column(
                children: [
                  const SizedBox(height: 16),
                  Text(
                    "Ending Positions",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  FieldHeatMap(
                    events:
                        [
                          for (final match in data.event.teamRecordedMatches(
                            widget.teamNumber,
                          ))
                            match.value.robot[widget.teamNumber.toString()]!
                                .timelineInterpolatedBlueNormalized(
                                  data.event.config.fieldStyle,
                                )
                                .where((element) => element.isPositionEvent)
                                .lastOrNull,
                        ].nonNulls.toList(),
                  ),
                ],
              ),
              Column(
                children: [
                  const SizedBox(height: 16),
                  Text(
                    "Driving Tendencies",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  FieldHeatMap(
                    events: [
                      for (final match in data.event.teamRecordedMatches(
                        widget.teamNumber,
                      ))
                        ...?match.value.robot[widget.teamNumber.toString()]
                            ?.timelineInterpolatedBlueNormalized(
                              data.event.config.fieldStyle,
                            )
                            .where((event) => event.isPositionEvent),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const Divider(height: 32),
          Center(
            child: Text(
              "Scouting",
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          ScoutingResultsViewer(teamNumber: widget.teamNumber, snoutData: data),
        ],
      ),
    );
  }
}

class ScoutingResultsViewer extends StatelessWidget {
  final int teamNumber;
  final DataProvider snoutData;

  const ScoutingResultsViewer({
    super.key,
    required this.teamNumber,
    required this.snoutData,
  });

  @override
  Widget build(BuildContext context) {
    final data = snoutData.event.pitscouting[teamNumber.toString()];
    if (data == null) {
      return const ListTile(title: Text("Team has no pit scouting data"));
    }
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 800),
        child: Column(
          children: [
            for (final item in snoutData.event.config.pitscouting) ...[
              DynamicValueViewer(itemType: item, value: data[item.id]),
              Container(
                padding: const EdgeInsets.only(right: 16),
                alignment: Alignment.centerRight,
                child: EditAudit(
                  path: Patch.buildPath([
                    'pitscouting',
                    '$teamNumber',
                    item.id,
                  ]),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class DynamicValueViewer extends StatelessWidget {
  final SurveyItem itemType;
  final dynamic value;

  const DynamicValueViewer({
    super.key,
    required this.itemType,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    if (value == null) {
      return ListTile(
        title: Text(itemType.label),
        subtitle: const Text("NOT SET", style: TextStyle(color: warningColor)),
      );
    }

    if (itemType.type == SurveyItemType.picture) {
      return ListTile(
        title: Text(itemType.label),
        subtitle: ImageViewer(
          child: Image(
            image: snoutImageCache.getCached(value),
            height: 500,
            fit: BoxFit.contain,
          ),
        ),
      );
    }

    return ListTile(
      title: Text(itemType.label),
      subtitle: SelectableText(value.toString()),
    );
  }
}
