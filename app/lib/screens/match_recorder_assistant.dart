import 'package:app/data_submit_login.dart';
import 'package:app/providers/data_provider.dart';
import 'package:app/services/snout_image_cache.dart';
import 'package:app/style.dart';
import 'package:app/screens/match_recorder.dart';
import 'package:app/screens/view_team_page.dart';
import 'package:app/widgets/load_status_or_error_bar.dart';
import 'package:app/widgets/team_avatar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:snout_db/actions/write_dataitem.dart';
import 'package:snout_db/actions/write_matchtrace.dart';
import 'package:snout_db/data_item.dart';
import 'package:snout_db/event/match_schedule_item.dart';
import 'package:snout_db/match_trace.dart';
import 'package:snout_db/snout_chain.dart';

//Displays a list of teams for the match with pictures
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
              scrollDirection: isWideScreen(context)
                  ? Axis.horizontal
                  : Axis.vertical,
              children: [
                for (final team in match.blue)
                  _getTeamTile(
                    team: team,
                    onTap: () => _recordTeam(
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
                    onTap: () => _recordTeam(
                      widget.matchid,
                      team,
                      match.getAllianceOf(team),
                    ),
                    subtitle: "Red ${match.red.indexOf(team) + 1}",
                    subtitleColor: Colors.red,
                  ),

                SizedBox(
                  height: 200,
                  width: 200,
                  child: Column(
                    children: [
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
                              .map<DropdownMenuItem<Alliance>>((
                                Alliance value,
                              ) {
                                return DropdownMenuItem<Alliance>(
                                  value: value,
                                  child: Text(
                                    value.toString(),
                                    style: TextStyle(
                                      color: getAllianceUIColor(value),
                                    ),
                                  ),
                                );
                              })
                              .toList(),
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
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  //Emulate the list tile but support a larger icon
  Widget _getTeamTile({
    required int team,
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
        child: Image(image: memoryImageProvider(data), fit: BoxFit.cover),
      );
    }

    int numRecordings = snoutData.event.teamRecordedMatches(team).length;
    bool inInMatchWithOurTeam = snoutData.event
        .matcheScheduledWithTeam(snoutData.event.config.team)
        .any((match) => match.isScheduledToHaveTeam(team));

    return InkWell(
      onTap: onTap,
      child: Flex(
        direction: isWideScreen(context) ? Axis.vertical : Axis.horizontal,
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
              // if (isRecommended) const Text("Recommended"),
              Row(
                children: [
                  FRCTeamAvatar(teamNumber: team),
                  const SizedBox(width: 4),
                  Text("$team", style: Theme.of(context).textTheme.bodyLarge),
                ],
              ),
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
    );
  }

  void _recordTeam(String matchid, int team, Alliance alliance) async {
    final snoutData = context.read<DataProvider>();
    MatchScheduleItem match = snoutData.event.schedule[widget.matchid]!;
    RobotMatchTraceDataResult? result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MatchRecorderPage(
          team: team,
          teamAlliance: alliance,
          matchDescription: match.label,
        ),
      ),
    );

    if (result != null && mounted) {
      final traceAction = ActionWriteMatchTrace(
        MatchTrace(match: matchid, team: team, trace: result.trace),
      );

      await submitMultipleActions(context, [
        traceAction,
        ...result.survey.entries.map(
          (item) => ActionWriteDataItem(
            DataItem.matchTeam(matchid, team, item.key, item.value),
          ),
        ),
      ]);

      if (mounted) {
        Navigator.pop(context);
      }
    }
  }
}
