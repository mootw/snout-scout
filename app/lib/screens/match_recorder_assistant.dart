import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:app/api.dart';
import 'package:app/edit_lock.dart';
import 'package:app/eventdb_state.dart';
import 'package:app/helpers.dart';
import 'package:app/screens/match_recorder.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:snout_db/event/match.dart';
import 'package:snout_db/event/robotmatchresults.dart';
import 'package:snout_db/patch.dart';
import 'package:snout_db/snout_db.dart';

//Displays a list of teams and gives recommends a random robot.
//However before picking a recommendation it queries all
//robots being picked and removes those robots from the list.
//if the device is offline it just picks one randomly.
//there will be chance of a collision but this should mitigate it
//especially if most devices are online.
class MatchRecorderAssistantPage extends StatefulWidget {
  const MatchRecorderAssistantPage({super.key, required this.matchid});
  final String matchid;

  @override
  State<MatchRecorderAssistantPage> createState() =>
      _MatchRecorderAssistantPageState();
}

class _MatchRecorderAssistantPageState
    extends State<MatchRecorderAssistantPage> {
  final TextEditingController _textController = TextEditingController();
  Alliance _alliance = Alliance.blue;
  int? _recommended;

  @override
  void initState() {
    super.initState();
    final snoutData = context.read<EventDB>();
    FRCMatch match = snoutData.db.matches[widget.matchid]!;

    //Pick a recommended team that is not already being scouted
    () async {
      final teams = {...match.red, ...match.blue};
      for (final scoutedTeam in await _getScoutedTeams(match, teams)) {
        teams.remove(scoutedTeam);
      }
      setState(() {
        final list = (teams.toList()..shuffle());
        if (list.isNotEmpty) {
          _recommended = list.first;
        }
      });
    }();
  }

  //Updates teams that are already being scouted.
  Future<Set<int>> _getScoutedTeams(FRCMatch match, Set<int> teams) async {
    final alreadyScouted = <int>{};
    //Add teams that already have recordings
    for (final team in teams) {
      if (match.robot[team.toString()] != null) {
        alreadyScouted.add(team);
      }
    }
    //all calls will occur at the same time.
    List<Future> futures = [];
    for (final team in teams) {
      futures.add(apiClient
          .get(editLockUri,
              headers: {"key": "match:${widget.matchid}:$team:timeline"})
          .timeout(const Duration(seconds: 1))
          .then((isLocked) {
            if (isLocked.body == "true") {
              alreadyScouted.add(team);
            }
          }));
    }
    try {
      await Future.wait(futures);
    } catch (e) {
      print(e);
    }
    return alreadyScouted;
  }

  @override
  Widget build(BuildContext context) {
    final snoutData = context.watch<EventDB>();
    FRCMatch match = snoutData.db.matches[widget.matchid]!;
    return Scaffold(
      appBar: AppBar(title: Text("Match Recording: ${match.description}")),
      body: ListView(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    for (final team in match.red)
                      _getTeamTile(
                          team: team,
                          isRecommended: _recommended == team,
                          onTap: () => _recordTeam(
                              widget.matchid, team, match.getAllianceOf(team)),
                          subtitle: "Red ${match.red.indexOf(team) + 1}",
                          subtitleColor: Colors.red),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    for (final team in match.blue)
                      _getTeamTile(
                          team: team,
                          isRecommended: _recommended == team,
                          onTap: () => _recordTeam(
                              widget.matchid, team, match.getAllianceOf(team)),
                          subtitle: "Blue ${match.blue.indexOf(team) + 1}",
                          subtitleColor: Colors.blue),
                  ],
                ),
              )
            ],
          ),
          const Divider(),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            Flexible(
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Wrong team?',
                ),
                autocorrect: false,
                keyboardType: TextInputType.number,
                controller: _textController,
              ),
            ),
            Flexible(
              child: DropdownButton<Alliance>(
                value: _alliance,
                onChanged: (Alliance? value) {
                  setState(() {
                    _alliance = value!;
                  });
                },
                items: [Alliance.blue, Alliance.red]
                    .map<DropdownMenuItem<Alliance>>((Alliance value) {
                  return DropdownMenuItem<Alliance>(
                    value: value,
                    child: Text(value.toString(),
                        style: TextStyle(color: getAllianceColor(value))),
                  );
                }).toList(),
              ),
            ),
            Flexible(
              child: FilledButton.tonal(
                  onPressed: () async {
                    int team = int.parse(_textController.text);
                    _recordTeam(widget.matchid, team, _alliance);
                  },
                  child: const Text(
                    "Record Substitution",
                    textAlign: TextAlign.center,
                  )),
            ),
          ]),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  //Emulate the list tile but support a larger icon
  Widget _getTeamTile(
      {required int team,
      required bool isRecommended,
      required String subtitle,
      required GestureTapCallback onTap,
      required Color subtitleColor}) {
    final snoutData = context.watch<EventDB>();
    Widget? image;
    final data = snoutData.db.pitscouting[team.toString()]?['robot_picture'];
    if (data != null) {
      image = AspectRatio(
          aspectRatio: 1,
          child: Image.memory(
              Uint8List.fromList(base64Decode(data).cast<int>()),
              fit: BoxFit.cover));
    }

    return InkWell(
      onTap: onTap,
      child: Container(
        color: isRecommended ? Theme.of(context).colorScheme.onPrimary : null,
        child: Row(children: [
          SizedBox(
              height: 120,
              width: 120,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Center(child: image ?? const Text("No Image")),
              )),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isRecommended) const Text("Recommended"),
              Text("$team", style: Theme.of(context).textTheme.bodyLarge),
              Text(subtitle,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: subtitleColor)),
            ],
          )
        ]),
      ),
    );
  }

  void _recordTeam(String matchid, int team, Alliance alliance) async {
    final snoutData = context.read<EventDB>();
    RobotMatchResults? result = await navigateWithEditLock(
        context,
        "match:$matchid:$team:timeline",
        () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      MatchRecorderPage(team: team, teamAlliance: alliance)),
            ));

    if (result != null) {
      Patch patch = Patch(
          time: DateTime.now(),
          path: ['matches', matchid, 'robot', team.toString()],
          data: jsonEncode(result));

      await snoutData.addPatch(patch);
    }
  }
}
