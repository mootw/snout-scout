import 'package:app/providers/data_provider.dart';
import 'package:app/widgets/fieldwidget.dart';
import 'package:app/screens/view_team_page.dart';
import 'package:app/widgets/team_avatar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:snout_db/config/matcheventconfig.dart';

class AnalysisHeatMapByEventType extends StatefulWidget {
  const AnalysisHeatMapByEventType({super.key});

  @override
  State<AnalysisHeatMapByEventType> createState() =>
      _AnalysisHeatMapByEventTypeState();
}

class _AnalysisHeatMapByEventTypeState
    extends State<AnalysisHeatMapByEventType> {
  MatchEventConfig? _selectedEvent;

  @override
  void initState() {
    super.initState();
    //select the first event type if it is exists
    _selectedEvent = context
        .read<DataProvider>()
        .event
        .config
        .matchscouting
        .events
        .firstOrNull;
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text("Heatmap By Event Type")),
      body: Column(
        children: [
          DropdownButton<MatchEventConfig>(
            value: _selectedEvent,
            onChanged: (MatchEventConfig? value) {
              // This is called when the user selects an item.
              setState(() {
                _selectedEvent = value!;
              });
            },
            items: data.event.config.matchscouting.events
                .map<DropdownMenuItem<MatchEventConfig>>((
                  MatchEventConfig value,
                ) {
                  return DropdownMenuItem<MatchEventConfig>(
                    value: value,
                    child: Text(value.label),
                  );
                })
                .toList(),
          ),
          if (_selectedEvent != null)
            Expanded(
              child: SingleChildScrollView(
                child: Center(
                  child: Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      for (final team in data.event.teams)
                        Column(
                          children: [
                            FieldHeatMap(
                              events: [
                                for (final match
                                    in data.event.teamRecordedMatches(team))
                                  ...?match.value.robot[team.toString()]
                                      ?.timelineBlueNormalized(
                                        data.event.config.fieldStyle,
                                      )
                                      .where(
                                        (event) =>
                                            event.id == _selectedEvent!.id,
                                      ),
                              ],
                            ),
                            TextButton(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      TeamViewPage(teamNumber: team),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  FRCTeamAvatar(teamNumber: team),
                                  SizedBox(width: 4),
                                  Text(team.toString()),
                                ],
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
