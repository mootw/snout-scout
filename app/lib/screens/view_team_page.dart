import 'dart:convert';
import 'dart:typed_data';

import 'package:app/edit_lock.dart';
import 'package:app/main.dart';
import 'package:app/match_card.dart';
import 'package:app/scout_team.dart';
import 'package:app/scouting_tools/scouting_tool.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:snout_db/event/pitscoutresult.dart';
import 'package:snout_db/season/surveyitem.dart';

class TeamViewPage extends StatefulWidget {
  final int teamNumber;

  const TeamViewPage({Key? key, required this.teamNumber}) : super(key: key);

  @override
  State<TeamViewPage> createState() => _TeamViewPageState();
}

class _TeamViewPageState extends State<TeamViewPage> {
  @override
  Widget build(BuildContext context) {
    return Consumer<SnoutScoutData>(builder: (context, snoutData, child) {
      return Scaffold(
          appBar: AppBar(
            actions: [
              TextButton(
                  onPressed: () async {
                    //Get existing scouting data.
                    var result = await navigateWithEditLock(
                        context,
                        "scoutteam:${widget.teamNumber}",
                        () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => PitScoutTeamPage(
                                      team: widget.teamNumber,
                                      config: snoutData.season,
                                      oldData:
                                          snoutData.currentEvent.pitscouting[
                                              widget.teamNumber.toString()])),
                            ));
                    if (result != null) {
                      //Data has been saved
                      setState(() {});
                    }
                  },
                  child: Text("Scout"))
            ],
            title: Text("Team ${widget.teamNumber}"),
          ),
          body: ListView(
            shrinkWrap: true,
            children: [
              ScoutingResultsViewer(
                  teamNumber: widget.teamNumber, snoutData: snoutData),
              Divider(height: 32),
              //Display this teams matches
              Column(
                children: [
                  for (var match
                      in snoutData.currentEvent.matchesWithTeam(widget.teamNumber))
                    MatchCard(match: match, focusTeam: widget.teamNumber),
                ],
              ),
              Divider(height: 32),
              Text(
                  "Performance Summary like min-max-average metrics over all games"),
              Divider(height: 32),
              Text(
                  "Graphs like performance of specific metrics over multiple matches"),
              Divider(height: 32),
              Text(
                  "Maps like heatmap of positions across all games, events (like shooting positions) heat map, and starting position heatmap"),
            ],
          ));
    });
  }
}

class ScoutingResultsViewer extends StatelessWidget {
  final int teamNumber;
  final SnoutScoutData snoutData;

  const ScoutingResultsViewer(
      {Key? key, required this.teamNumber, required this.snoutData})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    var data = snoutData.currentEvent.pitscouting[teamNumber.toString()];

    if (data == null) {
      return ListTile(title: Text("Team has no pit scouting data"));
    }

    return Column(
      children: [
        for (var item in snoutData.season.pitscouting)
          ScoutingResult(item: item, survey: data)
      ],
    );
  }
}

class ScoutingResult extends StatelessWidget {
  final SurveyItem item;
  final PitScoutResult survey;

  const ScoutingResult({Key? key, required this.item, required this.survey})
      : super(key: key);

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
