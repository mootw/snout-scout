import 'package:app/providers/data_provider.dart';
import 'package:app/style.dart';
import 'package:app/widgets/team_avatar.dart';
import 'package:app/widgets/timeduration.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:app/screens/match_page.dart';
import 'package:flutter/material.dart';
import 'package:snout_db/event/match_data.dart';
import 'package:snout_db/event/match_schedule_item.dart';
import 'package:snout_db/event/matchresults.dart';
import 'package:snout_db/snout_chain.dart';

const double matchCardHeight = 40;

const BorderRadius matchCardRadius = BorderRadius.all(Radius.circular(8));

const TextStyle whiteText = TextStyle(color: Colors.white, fontSize: 12);

const winOutlineColor = Colors.white;

class MatchCard extends StatelessWidget {
  final MatchData? match;
  final MatchResultValues? results;
  final MatchScheduleItem matchSchedule;
  final int? focusTeam;
  final Color? color;

  const MatchCard({
    super.key,
    required this.match,
    required this.results,
    required this.matchSchedule,
    this.focusTeam,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final snoutData = context.watch<DataProvider>();

    final matchTime = results != null
        ? results!.time
        : matchSchedule.scheduledTime.add(
            snoutData.event.scheduleDelay ?? Duration.zero,
          );

    return Align(
      alignment: Alignment.center,
      child: Material(
        borderRadius: matchCardRadius,
        color: color ?? Theme.of(context).colorScheme.surfaceContainerHigh,
        child: SizedBox(
          height: matchCardHeight,
          child: InkWell(
            borderRadius: matchCardRadius,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MatchPage(matchid: matchSchedule.id),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: matchCardRadius,
                    color: matchSchedule.isScheduledToHaveTeam(focusTeam ?? 0)
                        ? getAllianceUIColor(
                            matchSchedule.getAllianceOf(focusTeam ?? 0),
                          )
                        : null,
                  ),
                  width: 60,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TimeDuration(time: matchTime, style: whiteText),
                      Text(
                        DateFormat.E().format(matchTime.toLocal()),
                        style: whiteText,
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 75,
                  child: Text(
                    matchSchedule.label,
                    textAlign: TextAlign.center,
                    style: whiteText,
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            border:
                                results?.winner == Alliance.red ||
                                    results?.winner == Alliance.tie
                                ? Border.all(color: winOutlineColor, width: 1)
                                : null,
                            color: Colors.red.withAlpha(128),
                          ),
                          height: 20,
                          width: 170,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              for (final team in matchSchedule.red)
                                Flexible(
                                  child: Row(
                                    children: [
                                      const SizedBox(width: 3),
                                      FRCTeamAvatar(teamNumber: team, size: 15),
                                      const SizedBox(width: 2),
                                      Text(team.toString(), style: whiteText),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 30,
                          child: Text(
                            results?.redScore != null
                                ? results!.redScore.toString()
                                : "-",
                            style: whiteText,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Container(
                          height: 20,
                          width: 170,
                          decoration: BoxDecoration(
                            border:
                                results?.winner == Alliance.blue ||
                                    results?.winner == Alliance.tie
                                ? Border.all(color: winOutlineColor, width: 1)
                                : null,
                            color: Colors.blueAccent.withAlpha(128),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              for (final team in matchSchedule.blue)
                                Flexible(
                                  child: Row(
                                    children: [
                                      const SizedBox(width: 3),
                                      FRCTeamAvatar(teamNumber: team, size: 15),
                                      const SizedBox(width: 2),
                                      Text(team.toString(), style: whiteText),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 30,
                          child: Text(
                            results?.blueScore != null
                                ? results!.blueScore.toString()
                                : "-",
                            style: whiteText,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
