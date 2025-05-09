import 'dart:async';

import 'package:app/api.dart';
import 'package:app/data_submit_login.dart';
import 'package:app/edit_lock.dart';
import 'package:app/providers/data_provider.dart';
import 'package:app/services/snout_image_cache.dart';
import 'package:app/style.dart';
import 'package:app/providers/identity_provider.dart';
import 'package:app/screens/match_recorder.dart';
import 'package:app/screens/view_team_page.dart';
import 'package:app/widgets/load_status_or_error_bar.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import 'package:snout_db/event/match_data.dart';
import 'package:snout_db/event/match_schedule_item.dart';
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
  Set<int> _alreadyScoutedTeams = {};

  late Timer _checkScoutedTeams;

  @override
  void dispose() {
    _checkScoutedTeams.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    _checkScoutedTeams = Timer.periodic(
      Duration(seconds: 4),
      (_) => _pickRecommendedTeams(),
    );
    _pickRecommendedTeams();
  }

  Future _pickRecommendedTeams() async {
    final snoutData = context.read<DataProvider>();
    MatchScheduleItem matchSchedule = snoutData.event.schedule[widget.matchid]!;
    //Pick a recommended team that is not already being scouted
    final teams = {...matchSchedule.red, ...matchSchedule.blue};
    final scoutedTeams = await _getScoutedTeams(
      matchSchedule.getData(snoutData.event),
      teams,
    );
    final availableTeams = teams.difference(scoutedTeams);
    final list = (availableTeams.toList()..shuffle());
    setState(() {
      if (_recommended == null) {
        if (list.isNotEmpty) {
          _recommended = list.first;
        }
      } else {
        if (list.contains(_recommended) == false) {
          // We need to pick a new recommended, because the list changed
          // to not include the last recommended value
          if (list.isNotEmpty) {
            _recommended = list.first;
          }
        }
      }

      _alreadyScoutedTeams = scoutedTeams;
    });
  }

  //Updates teams that are already being scouted.
  Future<Set<int>> _getScoutedTeams(MatchData? match, Set<int> teams) async {
    final alreadyScouted = <int>{};
    //Add teams that already have recordings
    for (final team in teams) {
      if (match?.robot[team.toString()] != null) {
        alreadyScouted.add(team);
      }
    }
    //all calls will occur at the same time.
    List<Future> futures = [];
    for (final team in teams) {
      futures.add(
        apiClient
            .get(
              context.read<DataProvider>().dataSourceUri.resolve("/edit_lock"),
              headers: {"key": "match:${widget.matchid}:$team:timeline"},
            )
            .timeout(const Duration(seconds: 1))
            .then((isLocked) {
              if (isLocked.body == "true") {
                alreadyScouted.add(team);
              }
            }),
      );
    }
    try {
      await Future.wait(futures);
    } catch (e) {
      Logger.root.severe("error getting teams being scouted", e);
    }
    return alreadyScouted;
  }

  @override
  Widget build(BuildContext context) {
    final snoutData = context.watch<DataProvider>();
    MatchScheduleItem match = snoutData.event.schedule[widget.matchid]!;
    return Scaffold(
      appBar: AppBar(
        title: Text("Recording ${match.label}"),
        bottom: const LoadOrErrorStatusBar(),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              scrollDirection: isWideScreen(context) ? Axis.horizontal : Axis.vertical,
              children: [
                for (final team in match.blue)
                  _getTeamTile(
                    team: team,
                    isRecommended: _recommended == team,
                    onTap:
                        () => _recordTeam(
                          widget.matchid,
                          team,
                          match.getAllianceOf(team),
                        ),
                    subtitle: "Blue ${match.blue.indexOf(team) + 1}",
                    subtitleColor: Colors.blue,
                  ),
                for (final team in match.red)
                  _getTeamTile(
                    team: team,
                    isRecommended: _recommended == team,
                    onTap:
                        () => _recordTeam(
                          widget.matchid,
                          team,
                          match.getAllianceOf(team),
                        ),
                    subtitle: "Red ${match.red.indexOf(team) + 1}",
                    subtitleColor: Colors.red,
                  ),
              ],
            ),
          ),
          const Divider(height: 0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Flexible(
                child: TextField(
                  decoration: const InputDecoration(hintText: 'Wrong team?'),
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
                  items:
                      [
                        Alliance.blue,
                        Alliance.red,
                      ].map<DropdownMenuItem<Alliance>>((Alliance value) {
                        return DropdownMenuItem<Alliance>(
                          value: value,
                          child: Text(
                            value.toString(),
                            style: TextStyle(color: getAllianceUIColor(value)),
                          ),
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
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  //Emulate the list tile but support a larger icon
  Widget _getTeamTile({
    required int team,
    required bool isRecommended,
    required String subtitle,
    required GestureTapCallback onTap,
    required Color subtitleColor,
  }) {
    final snoutData = context.watch<DataProvider>();
    Widget? image;
    final data =
        snoutData.event.pitscouting[team.toString()]?[robotPictureReserved];
    if (data != null) {
      image = AspectRatio(
        aspectRatio: 1,
        child: Image(image: snoutImageCache.getCached(data), fit: BoxFit.cover),
      );
    }

    int numRecordings = snoutData.event.teamRecordedMatches(team).length;
    bool inInMatchWithOurTeam = snoutData.event
        .matchesWithTeam(snoutData.event.config.team)
        .any((match) => match.isScheduledToHaveTeam(team));

    return InkWell(
      onTap: onTap,
      child: Container(
        color:
            _alreadyScoutedTeams.contains(team)
                ? Colors.blueGrey.withAlpha(70)
                : (isRecommended
                    ? Theme.of(context).colorScheme.onPrimary
                    : null),
        child: Row(
          children: [
            SizedBox(
              height: 140,
              width: 140,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Center(child: image ?? const Text("No Image")),
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isRecommended) const Text("Recommended"),
                Text("$team", style: Theme.of(context).textTheme.bodyLarge),
                Text(
                  subtitle,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: subtitleColor),
                ),
                Text("$numRecordings recording(s)"),
                if (inInMatchWithOurTeam) Text("alliance member"),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _recordTeam(String matchid, int team, Alliance alliance) async {
    final snoutData = context.read<DataProvider>();
    final identity = context.read<IdentityProvider>().identity;
    MatchScheduleItem match = snoutData.event.schedule[widget.matchid]!;
    RobotMatchResults? result = await navigateWithEditLock<RobotMatchResults>(
      context,
      "match:$matchid:$team:timeline",
      (context) => Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => MatchRecorderPage(
                team: team,
                teamAlliance: alliance,
                matchDescription: match.label,
              ),
        ),
      ),
    );

    if (result != null && mounted) {
      Patch patch = Patch(
        identity: identity,
        time: DateTime.now(),
        path: Patch.buildPath(['matches', matchid, 'robot', team.toString()]),
        value: result.toJson(),
      );

      await submitData(context, patch);
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }
}
