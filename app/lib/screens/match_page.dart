import 'package:app/providers/identity_provider.dart';
import 'package:app/screens/edit_match_properties.dart';
import 'package:app/widgets/datasheet.dart';
import 'package:app/edit_lock.dart';
import 'package:app/providers/data_provider.dart';
import 'package:app/widgets/edit_audit.dart';
import 'package:app/widgets/fieldwidget.dart';
import 'package:app/style.dart';
import 'package:app/screens/analysis/match_preview.dart';
import 'package:app/screens/edit_match_results.dart';
import 'package:app/screens/match_recorder_assistant.dart';
import 'package:app/screens/view_team_page.dart';
import 'package:app/widgets/load_status_or_error_bar.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:snout_db/event/match_data.dart';
import 'package:snout_db/event/match_schedule_item.dart';
import 'package:snout_db/event/matchresults.dart';
import 'package:snout_db/patch.dart';
import 'package:url_launcher/url_launcher_string.dart';

class MatchPage extends StatefulWidget {
  const MatchPage({super.key, required this.matchid});

  final String matchid;

  @override
  State<MatchPage> createState() => _MatchPageState();
}

class _MatchPageState extends State<MatchPage> {
  @override
  Widget build(BuildContext context) {
    final snoutData = context.watch<DataProvider>();
    MatchData? match = snoutData.event.matches[widget.matchid];
    MatchScheduleItem? matchSchedule = snoutData.event.schedule[widget.matchid];

    context
        .read<DataProvider>()
        .updateStatus(context, "Looking at ${matchSchedule?.label}");
    return Scaffold(
      appBar: AppBar(
        title: Text('${matchSchedule?.label}'),
        bottom: const LoadOrErrorStatusBar(),
        actions: [
          FilledButton(
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (builder) =>
                          MatchRecorderAssistantPage(matchid: widget.matchid))),
              child: const Text("Scout")),
          const SizedBox(width: 12),
          FilledButton.tonal(
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (builder) => AnalysisMatchPreview(
                          red: matchSchedule?.red ?? [],
                          blue: matchSchedule?.blue ?? [],
                          matchLabel: matchSchedule?.label,
                          plan: Column(children: [
                            for (final item in snoutData
                                .event.config.matchscouting.properties) ...[
                              DynamicValueViewer(
                                  itemType: item,
                                  value: match?.properties?[item.id]),
                              Container(
                                  padding: const EdgeInsets.only(right: 16),
                                  alignment: Alignment.centerRight,
                                  child: EditAudit(
                                      path: Patch.buildPath([
                                    'matches',
                                    widget.matchid,
                                    'properties',
                                    item.id
                                  ]))),
                            ],
                          ])))),
              child: const Text("Preview")),
          const SizedBox(width: 12),
          //If there is a TBA event ID we will add a button to view the match id
          //since we will assume that all of the matches (or at least most)
          //have been imported to match the tba id format
          if (snoutData.event.config.tbaEventId != null)
            FilledButton.tonal(
              child: const Text("TBA"),
              onPressed: () => launchUrlString(
                  "https://www.thebluealliance.com/match/${widget.matchid}"),
            ),
          const SizedBox(width: 12),
        ],
      ),
      body: ListView(
        cacheExtent: 5000,
        children: [
          Row(
            children: [
              if (match?.results != null)
                Flexible(
                  child: Column(
                    children: [
                      DataTable(
                        columns: const [
                          DataColumn(label: Text("Results")),
                          DataColumn(label: Text("Red")),
                          DataColumn(label: Text("Blue")),
                        ],
                        rows: [
                          DataRow(cells: [
                            const DataCell(Text("Score")),
                            DataCell(Text(match!.results!.redScore.toString())),
                            DataCell(Text(match.results!.blueScore.toString())),
                          ]),
                        ],
                      ),
                      TextButton(
                        child: match.results == null
                            ? const Text("Add Results")
                            : const Text("Edit Results"),
                        onPressed: () async {
                          final identiy =
                              context.read<IdentityProvider>().identity;
                          final result =
                              await navigateWithEditLock<MatchResultValues>(
                                  context,
                                  "match:${matchSchedule?.label}:results",
                                  (context) => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => EditMatchResults(
                                            results: match.results,
                                            config: snoutData.event.config,
                                            matchID: widget.matchid),
                                      )));

                          if (result != null) {
                            Patch patch = Patch(
                                identity: identiy,
                                time: DateTime.now(),
                                path: Patch.buildPath(
                                    ['matches', widget.matchid, 'results']),
                                value: result.toJson());

                            await snoutData.newTransaction(patch);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              Flexible(
                child: Column(
                  children: [
                    ListTile(
                      title: const Text("Scheduled Time"),
                      subtitle: Text(DateFormat.jm().add_yMd().format(
                          matchSchedule?.scheduledTime.toLocal() ??
                              DateTime.now())),
                    ),
                    if (match?.results != null)
                      ListTile(
                        title: const Text("Actual Time"),
                        subtitle: Text(DateFormat.jm()
                            .add_yMd()
                            .format(match!.results!.time.toLocal())),
                      ),
                  ],
                ),
              ),
            ],
          ),
          Container(
              padding: const EdgeInsets.only(right: 16),
              alignment: Alignment.centerRight,
              child: EditAudit(
                  path:
                      Patch.buildPath(['matches', widget.matchid, 'results']))),
          const SizedBox(height: 8),
          DataSheet(
            title: 'Per Team Performance',
            //Data is a list of rows and columns
            columns: [
              DataItemWithHints(DataItem.fromText("Team")),
              for (final item in snoutData.event.config.matchscouting.processes)
                DataItemWithHints(DataItem.fromText(item.label),
                    largerIsBetter: item.isLargerBetter),
              for (final item in snoutData.event.config.matchscouting.survey)
                DataItemWithHints(DataItem.fromText(item.label)),
              DataItemWithHints(DataItem.fromText("Scout"))
            ],
            rows: [
              for (final team in <int>{
                ...matchSchedule?.blue ?? [],
                ...matchSchedule?.red ?? [],
                //Also include all of the surrogate robots
                ...match?.robot.keys.map((e) => int.tryParse(e)).nonNulls ?? []
              })
                [
                  DataItem(
                      displayValue: TextButton(
                          child: Text(
                              team.toString() +
                                  (matchSchedule?.isScheduledToHaveTeam(team) ==
                                          false
                                      ? " [surrogate]"
                                      : ""),
                              style: TextStyle(
                                // Get the alliance color first from the match data, then the schedule
                                color: getAllianceUIColor(match
                                        ?.robot[team.toString()]?.alliance) ??
                                    getAllianceUIColor(
                                        matchSchedule?.getAllianceOf(team)),
                              )),
                          onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        TeamViewPage(teamNumber: team)),
                              )),
                      exportValue: team.toString(),
                      sortingValue: team),
                  for (final item
                      in snoutData.event.config.matchscouting.processes)
                    DataItem.fromErrorNumber(snoutData.event
                            .runMatchResultsProcess(
                                item, match?.robot[team.toString()], team) ??
                        //Missing results, this is not an error
                        (value: null, error: null)),
                  for (final item
                      in snoutData.event.config.matchscouting.survey)
                    DataItem.fromSurveyItem(
                        match?.robot[team.toString()]?.survey[item.id], item),
                  DataItem.fromText(getAuditString(context
                      .watch<DataProvider>()
                      .database
                      .getLastPatchFor(Patch.buildPath(
                          ['matches', widget.matchid, 'robot', '$team'])))),
                ],
            ],
          ),
          const SizedBox(height: 32),
          if (match != null) FieldTimelineViewer(match: match),
          //Heatmaps for this specific match
          if (match != null)
            Wrap(
              spacing: 12,
              alignment: WrapAlignment.center,
              children: [
                Column(
                  children: [
                    const SizedBox(height: 16),
                    Text("Autos",
                        style: Theme.of(context).textTheme.titleMedium),
                    PathsViewer(
                      paths: [
                        for (final robot in match.robot.entries)
                          (
                            label: robot.key,
                            path: robot.value.timelineInterpolated
                                .where((element) => element.isInAuto)
                                .toList()
                          )
                      ],
                    ),
                  ],
                ),
                for (final eventType
                    in snoutData.event.config.matchscouting.events)
                  Column(children: [
                    const SizedBox(height: 16),
                    Text(eventType.label,
                        style: Theme.of(context).textTheme.titleMedium),
                    FieldHeatMap(events: [
                      for (final robot in match.robot.values)
                        ...robot.timeline
                            .where((event) => event.id == eventType.id),
                    ]),
                  ]),
                Column(
                  children: [
                    const SizedBox(height: 16),
                    Text("Driving Tendencies",
                        style: Theme.of(context).textTheme.titleMedium),
                    FieldHeatMap(events: [
                      for (final robot in match.robot.values)
                        ...robot.timelineInterpolated
                            .where((event) => event.isPositionEvent)
                    ]),
                  ],
                ),
              ],
            ),
          SizedBox(height: 16),
          Column(
            children: [
              Text("Properties",
                  style: Theme.of(context).textTheme.titleMedium),
              FilledButton(
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => EditMatchPropertiesPage(
                                  matchID: widget.matchid,
                                  config: snoutData
                                      .event.config.matchscouting.properties,
                                  initialData: match?.properties,
                                )));
                  },
                  child: const Text("Edit")),
              for (final item
                  in snoutData.event.config.matchscouting.properties) ...[
                DynamicValueViewer(
                    itemType: item, value: match?.properties?[item.id]),
                Container(
                    padding: const EdgeInsets.only(right: 16),
                    alignment: Alignment.centerRight,
                    child: EditAudit(
                        path: Patch.buildPath([
                      'matches',
                      widget.matchid,
                      'properties',
                      item.id
                    ]))),
              ]
            ],
          )
        ],
      ),
    );
  }
}
