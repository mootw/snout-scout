import 'package:app/data_submit_login.dart';
import 'package:app/screens/edit_data_items.dart';
import 'package:app/widgets/datasheet.dart';
import 'package:app/providers/data_provider.dart';
import 'package:app/widgets/edit_audit.dart';
import 'package:app/widgets/fieldwidget.dart';
import 'package:app/style.dart';
import 'package:app/screens/analysis/match_preview.dart';
import 'package:app/screens/edit_match_results.dart';
import 'package:app/screens/match_recorder_assistant.dart';
import 'package:app/screens/view_team_page.dart';
import 'package:app/widgets/load_status_or_error_bar.dart';
import 'package:app/widgets/scout_name_display.dart';
import 'package:app/widgets/team_avatar.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:snout_db/actions/write_matchresults.dart';
import 'package:snout_db/config/match_period_config.dart';
import 'package:snout_db/data_item.dart';
import 'package:snout_db/event/match_data.dart';
import 'package:snout_db/event/match_schedule_item.dart';
import 'package:snout_db/event/matchresults.dart';
import 'package:snout_db/match_result.dart';
import 'package:url_launcher/url_launcher_string.dart';

class MatchPage extends StatefulWidget {
  const MatchPage({super.key, required this.matchid});

  final String matchid;

  @override
  State<MatchPage> createState() => _MatchPageState();
}

class _MatchPageState extends State<MatchPage> {
  String? _filterPeriod;

  @override
  Widget build(BuildContext context) {
    final snoutData = context.watch<DataProvider>();
    MatchData? match = snoutData.event.matches[widget.matchid];
    MatchScheduleItem? matchSchedule = snoutData.event.schedule[widget.matchid];
    return Scaffold(
      appBar: AppBar(
        title: Text(matchSchedule?.label ?? widget.matchid),
        bottom: const LoadOrErrorStatusBar(),
        actions: [
          FilledButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (builder) =>
                    MatchRecorderAssistantPage(matchid: widget.matchid),
              ),
            ),
            child: const Text("Scout"),
          ),
          const SizedBox(width: 12),
          FilledButton.tonal(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (builder) => AnalysisMatchPreview(
                  red: matchSchedule?.red ?? [],
                  blue: matchSchedule?.blue ?? [],
                  matchLabel: matchSchedule?.label,
                  plan: Column(
                    children: [
                      for (final item
                          in snoutData
                              .event
                              .config
                              .matchscouting
                              .properties) ...[
                        DynamicValueViewer(
                          itemType: item,
                          value: snoutData.event.matchDataItems(
                            widget.matchid,
                          )?[item.id],
                        ),
                        Container(
                          padding: const EdgeInsets.only(right: 16),
                          alignment: Alignment.centerRight,
                          child: DataItemEditAudit(
                            dataItem: DataItem.match(
                              widget.matchid,
                              item.id,
                              null,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            child: const Text("Preview"),
          ),
          const SizedBox(width: 12),
          //If there is a TBA event ID we will add a button to view the match id
          //since we will assume that all of the matches (or at least most)
          //have been imported to match the tba id format
          if (snoutData.event.config.tbaEventId != null)
            FilledButton.tonal(
              child: const Text("TBA"),
              onPressed: () => launchUrlString(
                "https://www.thebluealliance.com/match/${widget.matchid}",
              ),
            ),
          const SizedBox(width: 12),
        ],
      ),
      body: ListView(
        cacheExtent: 5000,
        primary: true,
        children: [
          DataSheet(
            shrinkWrap: true,
            title: 'Per Team Performance',
            //Data is a list of rows and columns
            columns: [
              DataItemColumn.teamHeader(),
              for (final item in snoutData.event.config.matchscouting.processes)
                DataItemColumn.fromProcess(item),
              DataItemColumn.text('Scout'),
              for (final item in snoutData.event.config.matchscouting.survey)
                DataItemColumn(DataTableItem.fromText(item.label)),
            ],
            rows: [
              for (final team in <int>{
                ...matchSchedule?.blue ?? [],
                ...matchSchedule?.red ?? [],
                //Also include all of the surrogate robots
                ...match?.robot.keys.map((e) => int.tryParse(e)).nonNulls ?? [],
              })
                [
                  DataTableItem(
                    displayValue: TextButton(
                      child: Row(
                        children: [
                          FRCTeamAvatar(teamNumber: team),
                          const SizedBox(width: 4),
                          Text(
                            team.toString() +
                                (matchSchedule?.isScheduledToHaveTeam(team) ==
                                        false
                                    ? " [surrogate]"
                                    : ""),
                            style: TextStyle(
                              // Get the alliance color first from the match data, then the schedule
                              color:
                                  getAllianceUIColor(
                                    match?.robot[team.toString()]?.alliance,
                                  ) ??
                                  getAllianceUIColor(
                                    matchSchedule?.getAllianceOf(team),
                                  ),
                            ),
                          ),
                        ],
                      ),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TeamViewPage(teamNumber: team),
                        ),
                      ),
                    ),
                    exportValue: team.toString(),
                    sortingValue: team,
                  ),
                  for (final item
                      in snoutData.event.config.matchscouting.processes)
                    DataTableItem.fromErrorNumber(
                      snoutData.event.runMatchResultsProcess(
                            item,
                            match?.robot[team.toString()],
                            snoutData.event.matchTeamData(team, widget.matchid),
                            team,
                            widget.matchid,
                          ) ??
                          //Missing results, this is not an error
                          (value: null, error: null),
                    ),
                  traceTableItem(snoutData.database, widget.matchid, team),
                  for (final item
                      in snoutData.event.config.matchscouting.survey)
                    DataTableItem.fromSurveyItem(
                      snoutData.event.matchTeamData(
                        team,
                        widget.matchid,
                      )?[item.id],
                      item,
                    ),
                ],
            ],
          ),
          const SizedBox(height: 32),
          if (match != null) FieldTimelineViewer(match: match),

          if (match != null)
            Column(
              children: [
                const SizedBox(height: 16),
                Text("Autos", style: Theme.of(context).textTheme.titleMedium),
                PathsViewer(
                  paths: [
                    for (final robot in match.robot.entries)
                      (
                        label: robot.key,
                        path: robot.value.timelineInterpolated
                            .where(
                              (element) =>
                                  snoutData.event.config
                                      .getPeriodAtTime(element.timeDuration)
                                      .id ==
                                  autoPeriodId,
                            )
                            .toList(),
                      ),
                  ],
                ),
              ],
            ),

          //Heatmaps for this specific match
          Padding(
            padding: const EdgeInsets.only(top: 24, bottom: 8),
            child: Center(
              child: Text(
                "Event Heatmaps",
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ),
          Center(
            child: Wrap(
              spacing: 12,
              children: [
                for (final period in snoutData.event.config.matchperiods)
                  FilterChip(
                    label: Text(period.label),
                    selected: _filterPeriod == period.id,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _filterPeriod = period.id;
                        } else {
                          _filterPeriod = null;
                        }
                      });
                    },
                  ),
              ],
            ),
          ),

          if (match != null)
            Wrap(
              spacing: 12,
              alignment: WrapAlignment.center,
              children: [
                for (final eventType
                    in snoutData.event.config.matchscouting.events)
                  Column(
                    children: [
                      const SizedBox(height: 16),
                      Text(
                        eventType.label,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      FieldHeatMap(
                        events: [
                          for (final robot in match.robot.values)
                            ...robot.timeline.where(
                              (event) =>
                                  (_filterPeriod == null ||
                                      snoutData.event.config
                                              .getPeriodAtTime(
                                                event.timeDuration,
                                              )
                                              .id ==
                                          _filterPeriod) &&
                                  event.id == eventType.id,
                            ),
                        ],
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
                        for (final robot in match.robot.values)
                          ...robot.timelineInterpolated.where(
                            (event) =>
                                (_filterPeriod == null ||
                                    snoutData.event.config
                                            .getPeriodAtTime(event.timeDuration)
                                            .id ==
                                        _filterPeriod) &&
                                event.isPositionEvent,
                          ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          SizedBox(height: 16),
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 800),
              child: Column(
                children: [
                  Text(
                    "DataItems",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  FilledButton(
                    onPressed: () async {
                      await editMatchDataPage(context, widget.matchid);
                    },
                    child: const Text("Edit"),
                  ),
                  for (final item
                      in snoutData.event.config.matchscouting.properties) ...[
                    DynamicValueViewer(
                      itemType: item,
                      value: snoutData.event.matchDataItems(
                        widget.matchid,
                      )?[item.id],
                    ),
                    Container(
                      padding: const EdgeInsets.only(right: 16),
                      alignment: Alignment.centerRight,
                      child: DataItemEditAudit(
                        dataItem: DataItem.match(widget.matchid, item.id, null),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          Row(
            children: [
              if (snoutData.event.getMatchResults(widget.matchid) != null)
                Flexible(
                  child: ListTile(
                    title: const Text("Actual Time"),
                    subtitle: Text(
                      DateFormat.jm().add_yMd().format(
                        snoutData.event
                            .getMatchResults(widget.matchid)!
                            .time
                            .toLocal(),
                      ),
                    ),
                  ),
                ),
              Flexible(
                child: ListTile(
                  title: const Text("Scheduled Time"),
                  subtitle: Text(
                    DateFormat.jm().add_yMd().format(
                      matchSchedule?.scheduledTime.toLocal() ?? DateTime.now(),
                    ),
                  ),
                ),
              ),
            ],
          ),
          // TODO this entire layout is cooked and needs to be reworked
          if (snoutData.event.getMatchResults(widget.matchid) == null)
            TextButton(
              onPressed: () => editResults(matchSchedule, match, snoutData),
              child: Text("Add Results"),
            ),
          if (snoutData.event.getMatchResults(widget.matchid) != null)
            Column(
              children: [
                DataTable(
                  columns: const [
                    DataColumn(label: Text("Results")),
                    DataColumn(label: Text("Red")),
                    DataColumn(label: Text("Blue")),
                  ],
                  rows: [
                    DataRow(
                      cells: [
                        const DataCell(Text("Score")),
                        DataCell(
                          Text(
                            snoutData.event
                                .getMatchResults(widget.matchid)!
                                .redScore
                                .toString(),
                          ),
                        ),
                        DataCell(
                          Text(
                            snoutData.event
                                .getMatchResults(widget.matchid)!
                                .blueScore
                                .toString(),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                TextButton(
                  child: const Text("Edit Results"),
                  onPressed: () => editResults(matchSchedule, match, snoutData),
                ),
              ],
            ),
          Container(
            padding: const EdgeInsets.only(right: 16),
            alignment: Alignment.centerRight,
            child: snoutData.event.getMatchResults(widget.matchid) != null
                ? ScoutName(
                    db: snoutData.database,
                    scoutPubkey: snoutData
                        .event
                        .matchResults['/match/${widget.matchid}/result']!
                        .$2,
                  )
                : null,
          ),

          Text(widget.matchid),
        ],
      ),
    );
  }

  Future editResults(
    MatchScheduleItem? matchSchedule,
    MatchData? match,
    DataProvider snoutData,
  ) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditMatchResults(
          results:
              snoutData.event.getMatchResults(widget.matchid) ??
              MatchResultValues(
                time: DateTime.now(),
                redScore: 0,
                blueScore: 0,
              ),
          config: snoutData.event.config,
          matchID: widget.matchid,
        ),
      ),
    );

    if (result != null) {
      final action = ActionWriteMatchResults(
        MatchResult(match: widget.matchid, result: result),
      );
      if (mounted && context.mounted) {
        await submitData(context, action);
      }
    }
  }
}
