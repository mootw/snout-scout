import 'package:app/providers/identity_provider.dart';
import 'package:app/widgets/datasheet.dart';
import 'package:app/edit_lock.dart';
import 'package:app/providers/data_provider.dart';
import 'package:app/widgets/edit_audit.dart';
import 'package:app/widgets/fieldwidget.dart';
import 'package:app/helpers.dart';
import 'package:app/screens/analysis/match_preview.dart';
import 'package:app/screens/edit_match_results.dart';
import 'package:app/screens/match_recorder_assistant.dart';
import 'package:app/screens/view_team_page.dart';
import 'package:app/widgets/load_status_or_error_bar.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:snout_db/config/surveyitem.dart';
import 'package:snout_db/event/match.dart';
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
    FRCMatch match = snoutData.event.matches[widget.matchid]!;
    return Scaffold(
      appBar: AppBar(
        title: Text(match.description),
        bottom: const LoadOrErrorStatusBar(),
        actions: [
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
          const SizedBox(height: 8),
          Wrap(
            children: [
              const SizedBox(width: 12),
              FilledButton(
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (builder) => MatchRecorderAssistantPage(
                              matchid: widget.matchid))),
                  child: const Text("Scout This Match")),
              const SizedBox(width: 12),
              FilledButton.tonal(
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (builder) => AnalysisMatchPreview(
                              red: match.red, blue: match.blue))),
                  child: const Text("Preview")),
              const SizedBox(width: 12),
              TextButton(
                child: match.results == null
                    ? const Text("Add Results")
                    : const Text("Edit Results"),
                onPressed: () async {
                  final identiy = context.read<IdentityProvider>().identity;
                  final result = await navigateWithEditLock<MatchResultValues>(
                      context,
                      "match:${match.description}:results",
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

                    await snoutData.submitPatch(patch);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          DataSheet(
            title: 'Per Team Performance',
            //Data is a list of rows and columns
            columns: [
              DataItem.fromText("Team"),
              for (final item in snoutData.event.config.matchscouting.processes)
                DataItem.fromText(item.label),
              for (final item in snoutData.event.config.matchscouting.survey)
                DataItem.fromText(item.label),
              DataItem.fromText("Scout")
            ],
            rows: [
              for (final team in <int>{
                ...match.red,
                ...match.blue,
                //Also include all of the surrogate robots
                ...match.robot.keys.map((e) => int.tryParse(e)).whereNotNull()
              })
                [
                  DataItem(
                      displayValue: TextButton(
                          child: Text(
                              team.toString() +
                                  (match.hasTeam(team) == false
                                      ? " [surrogate]"
                                      : ""),
                              style: TextStyle(
                                  color: match.hasTeam(team) == false
                                      ? getAllianceColor(match
                                          .robot[team.toString()]!.alliance)
                                      : getAllianceColor(
                                          match.getAllianceOf(team)))),
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
                                item, match.robot[team.toString()], team) ??
                        //Missing results, this is not an error
                        (value: null, error: null)),
                  for (final item in snoutData.event.config.matchscouting.survey
                      .where(
                          (element) => element.type != SurveyItemType.picture))
                    DataItem.fromText(match
                        .robot[team.toString()]?.survey[item.id]
                        ?.toString()),
                  DataItem.fromText(getAuditString(context
                      .watch<DataProvider>()
                      .database
                      .getLastPatchFor(Patch.buildPath(
                          ['matches', widget.matchid, 'robot', '$team'])))),
                ],
            ],
          ),
          const SizedBox(height: 32),
          FieldTimelineViewer(match: match),
          //Heatmaps for this specific match
          Wrap(
            spacing: 12,
            alignment: WrapAlignment.center,
            children: [
              SizedBox(
                width: largeFieldSize,
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    Text("Autos",
                        style: Theme.of(context).textTheme.titleMedium),
                    FieldPaths(
                      paths: [
                        for (final robot in match.robot.values)
                          robot.timelineInterpolated
                              .where((element) => element.isInAuto)
                              .toList()
                      ],
                    ),
                  ],
                ),
              ),
              for (final eventType
                  in snoutData.event.config.matchscouting.events)
                SizedBox(
                  width: smallFieldSize,
                  child: Column(children: [
                    const SizedBox(height: 16),
                    Text(eventType.label,
                        style: Theme.of(context).textTheme.titleMedium),
                    FieldHeatMap(
                        events: match.robot.values.fold(
                            [],
                            (previousValue, element) => [
                                  ...previousValue,
                                  ...element.timeline.where(
                                      (event) => event.id == eventType.id)
                                ])),
                  ]),
                ),
              SizedBox(
                  width: smallFieldSize,
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      Text("Driving Tendencies",
                          style: Theme.of(context).textTheme.titleMedium),
                      FieldHeatMap(
                          events: match.robot.values.fold(
                              [],
                              (previousValue, element) => [
                                    ...previousValue,
                                    ...element.timelineInterpolated
                                        .where((event) => event.isPositionEvent)
                                  ])),
                    ],
                  )),
            ],
          ),

          ListTile(
            title: const Text("Scheduled Time"),
            subtitle: Text(DateFormat.jm()
                .add_yMd()
                .format(match.scheduledTime.toLocal())),
          ),
          if (match.results != null)
            ListTile(
              title: const Text("Actual Time"),
              subtitle: Text(DateFormat.jm()
                  .add_yMd()
                  .format(match.results!.time.toLocal())),
            ),
          if (match.results != null)
            Align(
              alignment: Alignment.center,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text("Results")),
                  DataColumn(label: Text("Red")),
                  DataColumn(label: Text("Blue")),
                ],
                rows: [
                  DataRow(cells: [
                    const DataCell(Text("Score")),
                    DataCell(Text(match.results!.redScore.toString())),
                    DataCell(Text(match.results!.blueScore.toString())),
                  ]),
                ],
              ),
            ),
          Container(
              padding: const EdgeInsets.only(right: 16),
              alignment: Alignment.centerRight,
              child: EditAudit(
                  path:
                      Patch.buildPath(['matches', widget.matchid, 'results']))),
        ],
      ),
    );
  }
}
