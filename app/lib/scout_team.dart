import 'package:app/api.dart';
import 'package:app/data/season_config.dart';
import 'package:app/data/scouting_result.dart';
import 'package:app/main.dart';
import 'package:app/scouting_tools/scouting_tool.dart';
import 'package:flutter/material.dart';

class PitScoutTeamPage extends StatefulWidget {
  final int team;
  final SeasonConfig config;
  final ScoutingResults? oldData;

  const PitScoutTeamPage(
      {Key? key, required this.team, required this.config, this.oldData})
      : super(key: key);

  @override
  State<PitScoutTeamPage> createState() => _PitScoutTeamPageState();
}

class _PitScoutTeamPageState extends State<PitScoutTeamPage> {
  Map<String, Survey> results = <String, Survey>{};

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    //Populate map to ensure non-null
    for (var item in widget.config.pitScouting.survey) {
      results[item.id] = Survey(id: item.id, type: item.type, value: null);
    }

    //populate old data on top
    if (widget.oldData != null) {
      for (var survey in widget.oldData!.survey) {
        results[survey.id] = survey;
      }
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
                  team: widget.team,
                  scout: await getName(),
                  time: DateTime.now().toIso8601String(),
                  survey: results.values.toList(),
                );

                var json = scoutingResultsToJson(scout_result);
                // print(json);
                var res = await apiClient.post(
                    Uri.parse("${await getServer()}/pit_scout"),
                    headers: {"jsondata": json});

                if (res.statusCode == 200) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Saved Scouting Data'),
                    duration: Duration(seconds: 4),
                  ));
                  Navigator.of(context).pop(true);
                }
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
