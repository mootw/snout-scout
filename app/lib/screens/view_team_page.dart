import 'dart:convert';
import 'dart:typed_data';

import 'package:app/edit_lock.dart';
import 'package:app/main.dart';
import 'package:app/match_card.dart';
import 'package:app/scout_team.dart';
import 'package:app/scouting_tools/scouting_tool.dart';
import 'package:flutter/material.dart';
import 'package:snout_db/event/pitscoutresult.dart';
import 'package:snout_db/patch.dart';
import 'package:snout_db/season/pitsurveyitem.dart';

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
            TextButton(
                onPressed: () async {
                  //Get existing scouting data.
                  var result = await navigateWithEditLock(
                      context,
                      "scoutteam:${widget.number}",
                      () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => PitScoutTeamPage(
                                    team: widget.number,
                                    config: snoutData.season!,
                                    oldData: snoutData.currentEvent.pitscouting[
                                        widget.number.toString()])),
                          ));
                  if (result != null) {
                    //Data has been saved
                    setState(() {});
                  }
                },
                child: Text("Scout"))
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
            Text("Performance Summary like min-max-average metrics over all games"),
            Divider(height: 32),
            Text("Graphs like performance of specific metrics over multiple matches"),
            Divider(height: 32),
            Text("Maps like heatmap of positions across all games, events (like shooting positions) heat map, and starting position heatmap"),
          ],
        ));
  }
}

class ScoutingResultsViewer extends StatelessWidget {
  final int teamNumber;

  const ScoutingResultsViewer({Key? key, required this.teamNumber})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    var data = snoutData.currentEvent.pitscouting[teamNumber.toString()];

    if (data == null) {
      return ListTile(title: Text("Team has no pit scouting data"));
    }
    
    return Column(
      children: [for (var item in snoutData.season!.pitscouting) ScoutingResult(item: item, survey: data)],
    );
  }
}

class ScoutingResult extends StatelessWidget {

  final PitSurveyItem item;
  final PitScoutResult survey;

  const ScoutingResult({Key? key, required this.item, required this.survey}) : super(key: key);

  dynamic get value => survey[item.id];

  @override
  Widget build(BuildContext context) {
    if (value == null) {
      return Container();
    }

    if (item.type == "picture") {
      return ListTile(
        title: Text(item.label),
        subtitle: SizedBox(
            height: scoutImageSize * 1.5,
            child: Image.memory(
              Uint8List.fromList(base64Decode(value).cast<int>()),
              scale: 0.5,
            )),
      );
    }

    return ListTile(
      title: Text(value.toString()),
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
    return Column(
      children: [
        for (var match in snoutData.currentEvent.matchesWithTeam(widget.team))
          MatchCard(match: match, focusTeam: widget.team),
      ],
    );
  }
}
