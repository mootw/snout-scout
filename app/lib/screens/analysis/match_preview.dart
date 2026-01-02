import 'package:app/screens/teams_page.dart';
import 'package:app/services/snout_image_cache.dart';
import 'package:app/widgets/datasheet.dart';
import 'package:app/providers/data_provider.dart';
import 'package:app/widgets/fieldwidget.dart';
import 'package:app/style.dart';
import 'package:app/screens/view_team_page.dart';
import 'package:app/widgets/image_view.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'package:snout_db/config/data_item_schema.dart';
import 'package:snout_db/event/frcevent.dart';
import 'package:snout_db/snout_chain.dart';

class AnalysisMatchPreview extends StatefulWidget {
  const AnalysisMatchPreview({
    super.key,
    required this.red,
    required this.blue,
    this.plan,
    this.matchLabel,
  });

  final String? matchLabel;
  final Widget? plan;
  final List<int> red;
  final List<int> blue;

  @override
  State<AnalysisMatchPreview> createState() => _AnalysisMatchPreviewState();
}

class _AnalysisMatchPreviewState extends State<AnalysisMatchPreview> {
  List<int> _red = [];
  List<int> _blue = [];

  @override
  void initState() {
    super.initState();
    _red = widget.red;
    _blue = widget.blue;

    if (_blue.isEmpty && _red.isEmpty) {
      SchedulerBinding.instance.addPostFrameCallback((_) => _editTeamsDialog());
    }
  }

  void _editTeamsDialog() async {
    final MatchAlliances? result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MatchPreviewAlliancePicker(
          startingAlliances: (red: _red, blue: _blue),
        ),
      ),
    );
    if (result != null) {
      setState(() {
        _red = result.red.nonNulls.toList();
        _blue = result.blue.nonNulls.toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();

    return Scaffold(
      appBar: AppBar(
        title: widget.matchLabel != null
            ? Text("${widget.matchLabel} Preview")
            : const Text("Match Preview"),
        actions: [
          TextButton(
            onPressed: _editTeamsDialog,
            child: const Text("Edit Teams"),
          ),
        ],
      ),
      body: ListView(
        cacheExtent: 5000,
        children: [
          if (widget.plan != null) widget.plan!,
          DataSheet(
            shrinkWrap: true,
            title: "Alliance Sum of Avg",
            columns: [
              DataItemColumn(DataTableItem.fromText("Alliance")),
              for (final item in data.event.config.matchscouting.processes)
                DataItemColumn.fromProcess(item),
            ],
            rows: [
              [
                const DataTableItem(
                  displayValue: Text(
                    "BLUE",
                    style: TextStyle(color: Colors.blue),
                  ),
                  exportValue: "BLUE",
                  sortingValue: "BLUE",
                ),
                for (final item in data.event.config.matchscouting.processes)
                  DataTableItem.fromNumber(
                    _blue.fold<double>(
                      0,
                      (previousValue, team) =>
                          previousValue +
                          (data.event.teamAverageProcess(team, item) ?? 0),
                    ),
                  ),
              ],
              [
                const DataTableItem(
                  displayValue: Text(
                    "RED",
                    style: TextStyle(color: Colors.red),
                  ),
                  exportValue: "RED",
                  sortingValue: "RED",
                ),
                for (final item in data.event.config.matchscouting.processes)
                  DataTableItem.fromNumber(
                    _red.fold<double>(
                      0,
                      (previousValue, team) =>
                          previousValue +
                          (data.event.teamAverageProcess(team, item) ?? 0),
                    ),
                  ),
              ],
            ],
          ),
          const Divider(height: 42),
          DataSheet(
            shrinkWrap: true,
            title: "Team Averages",
            columns: [
              DataItemColumn.teamHeader(),
              for (final item in data.event.config.matchscouting.processes)
                DataItemColumn.fromProcess(item),
              for (final item in data.event.config.matchscouting.survey)
                DataItemColumn.fromSurveyItem(item),
            ],
            rows: [
              for (final team in [..._blue, ..._red])
                [
                  DataTableItem(
                    displayValue: TextButton(
                      child: Text(
                        team.toString(),
                        style: TextStyle(
                          color: getAllianceUIColor(
                            _red.contains(team) ? Alliance.red : Alliance.blue,
                          ),
                        ),
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
                  for (final item in data.event.config.matchscouting.processes)
                    DataTableItem.fromNumber(
                      data.event.teamAverageProcess(team, item),
                    ),
                  for (final item in data.event.config.matchscouting.survey)
                    teamPostGameSurveyTableDisplay(data.event, team, item),
                ],
            ],
          ),
          const Divider(height: 32),
          ScrollConfiguration(
            behavior: MouseInteractableScrollBehavior(),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final (idx, team) in [..._blue, ..._red].indexed) ...[
                    Container(
                      color: (idx > 2 ? Colors.red : Colors.blue).withAlpha(
                        45 + ((idx % 2) * 45),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 250,
                            height: 250,
                            child:
                                context
                                        .read<DataProvider>()
                                        .event
                                        .pitscouting[team
                                        .toString()]?[robotPictureReserved] !=
                                    null
                                ? AspectRatio(
                                    aspectRatio: 1,
                                    child: ImageViewer(
                                      child: Image(
                                        image: memoryImageProvider(
                                          context
                                              .read<DataProvider>()
                                              .event
                                              .pitscouting[team
                                              .toString()]![robotPictureReserved]!,
                                        ),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  )
                                : const Text("No image"),
                          ),
                          TextButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    TeamViewPage(teamNumber: team),
                              ),
                            ),
                            child: Text(
                              team.toString(),
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    color: getAllianceUIColor(
                                      _red.contains(team)
                                          ? Alliance.red
                                          : Alliance.blue,
                                    ),
                                  ),
                            ),
                          ),
                          Column(
                            children: [
                              Text(
                                "Autos",
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              PathsViewer(
                                size: 280,
                                paths: [
                                  for (final match
                                      in data.event.teamRecordedMatches(team))
                                    (
                                      label:
                                          match.value
                                              .getSchedule(
                                                data.event,
                                                match.key,
                                              )
                                              ?.label ??
                                          match.key,
                                      path: match.value.robot[team.toString()]!
                                          .timelineInterpolatedBlueNormalized(
                                            data.event.config.fieldStyle,
                                          )
                                          .where((element) => element.isInAuto)
                                          .toList(),
                                    ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Column(
                            children: [
                              const SizedBox(height: 8),
                              Text(
                                "Starting Positions",
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              FieldHeatMap(
                                events: [
                                  for (final match
                                      in data.event.teamRecordedMatches(team))
                                    match.value.robot[team.toString()]!
                                        .timelineInterpolatedBlueNormalized(
                                          data.event.config.fieldStyle,
                                        )
                                        .where(
                                          (element) => element.isPositionEvent,
                                        )
                                        .firstOrNull,
                                ].nonNulls.toList(),
                              ),
                            ],
                          ),
                          Text(
                            "Autos Heatmap",
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          FieldHeatMap(
                            events: [
                              for (final match
                                  in data.event.teamRecordedMatches(team))
                                ...match.value.robot[team.toString()]!
                                    .timelineInterpolatedBlueNormalized(
                                      data.event.config.fieldStyle,
                                    )
                                    .where((element) => element.isInAuto),
                            ],
                          ),
                          for (final eventType
                              in data.event.config.matchscouting.events)
                            Column(
                              children: [
                                const SizedBox(height: 8),
                                Text(
                                  eventType.label,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                FieldHeatMap(
                                  events: [
                                    for (final match
                                        in data.event.teamRecordedMatches(team))
                                      ...?match.value.robot[team.toString()]
                                          ?.timelineBlueNormalized(
                                            data.event.config.fieldStyle,
                                          )
                                          .where(
                                            (event) => event.id == eventType.id,
                                          ),
                                  ],
                                ),
                              ],
                            ),
                          Column(
                            children: [
                              const SizedBox(height: 8),
                              Text(
                                "Ending Positions",
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              FieldHeatMap(
                                events: [
                                  for (final match
                                      in data.event.teamRecordedMatches(team))
                                    match.value.robot[team.toString()]!
                                        .timelineInterpolatedBlueNormalized(
                                          data.event.config.fieldStyle,
                                        )
                                        .where(
                                          (element) => element.isPositionEvent,
                                        )
                                        .lastOrNull,
                                ].nonNulls.toList(),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              const SizedBox(height: 8),
                              Text(
                                "Driving Tendencies",
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              FieldHeatMap(
                                events: [
                                  for (final match
                                      in data.event.teamRecordedMatches(team))
                                    ...match.value.robot[team.toString()]!
                                        .timelineInterpolatedBlueNormalized(
                                          data.event.config.fieldStyle,
                                        )
                                        .where(
                                          (event) => event.isPositionEvent,
                                        ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

DataTableItem teamPostGameSurveyTableDisplay(
  FRCEvent event,
  int team,
  DataItemSchema surveyItem,
) {
  final recordedMatches = event.teamRecordedMatches(team).toList();

  if (surveyItem.type == DataItemType.selector) {
    final Map<String, double> toReturn = {};

    for (final match in recordedMatches) {
      final surveyValue = event
          .matchSurvey(team, match.key)?[surveyItem.id]
          ?.toString();
      if (surveyValue == null) {
        continue;
      }
      if (toReturn[surveyValue] == null) {
        toReturn[surveyValue] = 1;
      } else {
        toReturn[surveyValue] = toReturn[surveyValue]! + 1;
      }
    }

    //Convert the map to be a percentage rather than total sum
    return DataTableItem.fromText(
      toReturn.entries
          .sorted((a, b) => Comparable.compare(b.value, a.value))
          .fold<String>(
            "",
            (previousValue, element) =>
                "${previousValue == "" ? "" : "$previousValue\n"} ${element.value}: ${element.key}",
          ),
    );
  }

  if (surveyItem.type == DataItemType.picture) {
    return DataTableItem.fromText("See team page or Robot Traces");
  }

  String result = "";
  // Reversed to display the most recent match first in the table
  for (final match in recordedMatches.reversed) {
    final surveyValue = event
        .matchSurvey(team, match.key)?[surveyItem.id]
        ?.toString();

    if (surveyValue == null) {
      continue;
    }

    result +=
        '${match.value.getSchedule(event, match.key)?.label ?? match.key}: $surveyValue\n';
  }

  return DataTableItem.fromText(result);
}

typedef MatchAlliances = ({List<int> red, List<int> blue});

class MatchPreviewAlliancePicker extends StatefulWidget {
  const MatchPreviewAlliancePicker({super.key, this.startingAlliances});

  final MatchAlliances? startingAlliances;

  @override
  State<MatchPreviewAlliancePicker> createState() =>
      MatchPreviewAlliancePickerState();
}

class MatchPreviewAlliancePickerState
    extends State<MatchPreviewAlliancePicker> {
  late MatchAlliances _alliances;

  int? _selectedTeam;

  @override
  void initState() {
    super.initState();
    _alliances = widget.startingAlliances != null
        ? (
            blue: widget.startingAlliances!.blue.toList(),
            red: widget.startingAlliances!.red.toList(),
          )
        : (blue: [], red: []);
  }

  @override
  Widget build(BuildContext context) {
    final snoutData = context.watch<DataProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Pick Alliances'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pop(context, _alliances);
            },
            icon: Icon(Icons.save),
          ),
        ],
      ),
      body: Column(
        children: [
          Row(
            children: [
              for (int i = 0; i < _alliances.blue.length; i++)
                Expanded(
                  child: Container(
                    color: Colors.blue,
                    child: Column(
                      children: [
                        Text('Blue ${i + 1}'),
                        Text(_alliances.blue[i].toString()),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _alliances.blue.removeAt(i);
                            });
                          },
                          icon: Icon(Icons.close),
                        ),
                        if (_selectedTeam != null)
                          FilledButton(
                            onPressed: () {
                              setState(() {
                                _alliances.blue[i] = _selectedTeam!;
                                _selectedTeam = null;
                              });
                            },
                            child: Text('SET $_selectedTeam'),
                          ),
                      ],
                    ),
                  ),
                ),
              if (_selectedTeam != null)
                Expanded(
                  child: Column(
                    children: [
                      Text('Blue'),
                      if (_selectedTeam != null)
                        FilledButton(
                          onPressed: () {
                            setState(() {
                              _alliances.blue.add(_selectedTeam!);
                              _selectedTeam = null;
                            });
                          },
                          child: Text('ADD $_selectedTeam'),
                        ),
                    ],
                  ),
                ),

              for (int i = 0; i < _alliances.red.length; i++)
                Expanded(
                  child: Container(
                    color: Colors.red,
                    child: Column(
                      children: [
                        Text('Red ${i + 1}'),
                        Text(_alliances.red[i].toString()),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _alliances.red.removeAt(i);
                            });
                          },
                          icon: Icon(Icons.close),
                        ),
                        if (_selectedTeam != null)
                          FilledButton(
                            onPressed: () {
                              setState(() {
                                _alliances.red[i] = _selectedTeam!;
                                _selectedTeam = null;
                              });
                            },
                            child: Text('SET $_selectedTeam'),
                          ),
                      ],
                    ),
                  ),
                ),
              if (_selectedTeam != null)
                Expanded(
                  child: Column(
                    children: [
                      Text('Red'),
                      if (_selectedTeam != null)
                        FilledButton(
                          onPressed: () {
                            setState(() {
                              _alliances.red.add(_selectedTeam!);
                              _selectedTeam = null;
                            });
                          },
                          child: Text('ADD $_selectedTeam'),
                        ),
                    ],
                  ),
                ),
            ],
          ),

          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Wrap(
                children: [
                  for (final team in snoutData.event.teams)
                    TeamListTile(
                      teamNumber: team,
                      onTap: () {
                        setState(() {
                          if (_selectedTeam == team) {
                            _selectedTeam = null;
                          } else {
                            _selectedTeam = team;
                          }
                        });
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
