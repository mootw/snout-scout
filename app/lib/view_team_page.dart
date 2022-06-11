import 'package:app/api.dart';
import 'package:app/data/matches.dart';
import 'package:app/data/season_config.dart';
import 'package:app/data/scouting_result.dart';
import 'package:app/main.dart';
import 'package:app/match_card.dart';
import 'package:app/matches_page.dart';
import 'package:app/scout_team.dart';
import 'package:flutter/material.dart';

class TeamViewPage extends StatefulWidget {
  final int number;

  const TeamViewPage({Key? key, required this.number}) : super(key: key);

  @override
  State<TeamViewPage> createState() => _TeamViewPageState();
}

class _TeamViewPageState extends State<TeamViewPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          actions: [
            IconButton(
                onPressed: () async {
                  //Get existing scouting data.
                  var res = await apiClient.get(
                      Uri.parse("${await getServer()}/pit_scout"),
                      headers: {"team": widget.number.toString()});

                  ScoutingResults? results;
                  if (res.statusCode == 200) {
                    results = scoutingResultsFromJson(res.body);
                  }

                  var config = snoutData.config;
                  if (config != null) {
                    var result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => PitScoutTeamPage(
                              team: widget.number,
                              config: config,
                              oldData: results)),
                    );
                    if (result == true) {
                      //We should setState and update
                      print("data saved");
                      setState(() {});
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('scouting config not loaded'),
                      duration: Duration(seconds: 4),
                    ));
                  }
                },
                icon: Icon(Icons.edit_attributes))
          ],
          title: Text("Team ${widget.number}"),
        ),
        body: ListView(
          shrinkWrap: true,
          children: [
            ScoutingResultsViewer(teamNumber: widget.number),
            Divider(height: 32),
            TeamMatchesViewer(team: widget.number),
            Divider(height: 32),
            Text("Performance Summary"),
            Divider(height: 32),
            Text("Graphs"),
          ],
        ));
  }
}

class ScoutingResultsViewer extends StatelessWidget {
  final int teamNumber;

  const ScoutingResultsViewer({Key? key, required this.teamNumber})
      : super(key: key);

  Future<ScoutingResults?> getScoutingResults() async {
    var res = await apiClient.get(Uri.parse("${await getServer()}/pit_scout"),
        headers: {"team": teamNumber.toString()});
    if (res.statusCode != 200) {
      return null;
    }
    return scoutingResultsFromJson(res.body);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ScoutingResults?>(
        future: getScoutingResults(),
        builder: ((context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.data == null) {
              return ListTile(title: Text("Team has no pit scouting data"));
            }

            var list = <Widget>[];

            for (var item in snapshot.data!.survey) {
              if (item.value != null) {
                list.add(ScoutingResult(result: item));
              }
            }

            return Column(
              children: [
                ...list,
              ],
            );
          }
          return CircularProgressIndicator.adaptive();
        }));
  }
}

class ScoutingResult extends StatelessWidget {
  final Survey result;

  const ScoutingResult({Key? key, required this.result}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (result.value == null) {
      return Container();
    }

    var config = snoutData.config;
    if (config == null) {
      return const Text("Season config is null");
    }

    ScoutingToolData item = config.pitScouting.survey
        .where((element) => element.id == result.id)
        .first;

    return ListTile(
      title: Text(result.value.toString()),
      subtitle: Text(item.label),
    );
  }
}

class TeamMatchesViewer extends StatefulWidget {
  final int team;
  const TeamMatchesViewer({Key? key, required this.team}) : super(key: key);

  @override
  State<TeamMatchesViewer> createState() => _TeamMatchesViewerState();
}

class _TeamMatchesViewerState extends State<TeamMatchesViewer> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: getMatches(teamFilter: widget.team),
        builder: (context, AsyncSnapshot snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Column(
              children: [
                for (var match in snapshot.data!)
                  MatchCard(match: match, focusTeam: widget.team),
              ],
            );
          }
          return CircularProgressIndicator.adaptive();
        });
  }
}
