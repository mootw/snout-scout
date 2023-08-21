import 'package:app/providers/data_provider.dart';
import 'package:app/widgets/fieldwidget.dart';
import 'package:app/screens/view_team_page.dart';
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
    _selectedEvent = context.read<DataProvider>().db.config.matchscouting.events.firstOrNull;
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text("Events Heatmap Analysis"),
      ),
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
            items: data.db.config.matchscouting.events
                .map<DropdownMenuItem<MatchEventConfig>>(
                    (MatchEventConfig value) {
              return DropdownMenuItem<MatchEventConfig>(
                value: value,
                child: Text(value.label),
              );
            }).toList(),
          ),
          if (_selectedEvent != null)
            Expanded(
              child: ListView(
                children: [
                  for (final team in data.db.teams) ...[
                    const SizedBox(height: 16),
                    TextButton(
                        onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    TeamViewPage(teamNumber: team))),
                        child: Text(team.toString())),
                    FieldHeatMap(
                        events: data.db.matchesWithTeam(team).fold(
                            [],
                            (previousValue, element) => [
                                  ...previousValue,
                                  ...element.robot.values.fold(
                                      [],
                                      (previousValue, element) => [
                                            ...previousValue,
                                            ...element
                                                .timelineRedNormalized(
                                                    data.db.config.fieldStyle)
                                                .where((event) =>
                                                    event.id ==
                                                    _selectedEvent!.id)
                                          ])
                                ])),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}
