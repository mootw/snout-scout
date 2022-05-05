import 'package:app/data/scouting_config.dart';
import 'package:app/data/scouting_result.dart';
import 'package:app/main.dart';
import 'package:app/scouting_tools/scouting_tool.dart';
import 'package:flutter/material.dart';

class ScoutTeamPage extends StatefulWidget {
  final int team;
  final ScoutingConfig config;

  const ScoutTeamPage({Key? key, required this.team, required this.config})
      : super(key: key);

  @override
  State<ScoutTeamPage> createState() => _ScoutTeamPageState();
}

class _ScoutTeamPageState extends State<ScoutTeamPage> {
  Map<String, Survey> results = <String, Survey>{};

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    for (var item in widget.config.pitScouting.survey) {
      results[item.id] = Survey(id: item.id, type: item.type, value: null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
              onPressed: () async {
                //Save the scouting results to the server!!
                var scout_result = ScoutingResults(
                  scout: await getName(),
                  time: DateTime.now().toIso8601String(),
                  survey: results.values.toList(),
                );

                var json = scoutingResultsToJson(scout_result);
              },
              icon: Icon(Icons.save))
        ],
        title: Text("Scouting ${widget.team}"),
      ),
      body: ListView(
        shrinkWrap: true,
        children: [
          for (var item in widget.config.pitScouting.survey)
            Container(
                padding: EdgeInsets.all(12),
                child: ScoutingToolWidget(
                  tool: item,
                  survey: results[item.id]!,
                )),
        ],
      ),
    );
  }
}
