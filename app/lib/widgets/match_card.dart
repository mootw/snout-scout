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

const double matchCardHeight = 46;

const TextStyle whiteText = TextStyle(color: Colors.white, fontSize: 12);
const TextStyle whiteTextBold = TextStyle(
  color: Colors.white,
  fontWeight: FontWeight.bold,
  fontSize: 12,
);

class MatchCard extends StatelessWidget {
  final MatchData? match;
  final MatchResultValues? results;
  final MatchScheduleItem matchSchedule;
  final int? focusTeam;

  const MatchCard({
    super.key,
    required this.match,
    required this.results,
    required this.matchSchedule,
    this.focusTeam,
  });

  @override
  Widget build(BuildContext context) {
    final snoutData = context.watch<DataProvider>();

    final matchTime = results != null
        ? results!.time
        : matchSchedule.scheduledTime.add(
            snoutData.event.scheduleDelay ?? Duration.zero,
          );

    return SizedBox(
      height: matchCardHeight,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MatchPage(matchid: matchSchedule.id),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 65,
              child: Column(
                children: [
                  TimeDuration(time: matchTime),
                  Text(DateFormat.E().format(matchTime.toLocal())),
                ],
              ),
            ),
            matchSchedule.isScheduledToHaveTeam(focusTeam ?? 0)
                ? SizedBox(
                    width: 19,
                    child: Icon(
                      Icons.star,
                      color: getAllianceUIColor(
                        matchSchedule.getAllianceOf(focusTeam ?? 0),
                      ),
                    ),
                  )
                : const SizedBox(width: 19),
            SizedBox(
              width: 80,
              child: Text(matchSchedule.label, textAlign: TextAlign.center),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: 20,
                  width: 200,
                  color: Colors.red.withAlpha(128),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      for (final team in matchSchedule.red)
                        Row(
                          children: [
                            FRCTeamAvatar(teamNumber: team),
                            const SizedBox(width: 2),
                            Text("$team", style: whiteText),
                          ],
                        ),
                      SizedBox(
                        width: 25,
                        child: Text(
                          results?.redScore != null
                              ? results!.redScore.toString()
                              : "-",
                          style:
                              results?.winner == Alliance.red ||
                                  results?.winner == Alliance.tie
                              ? whiteTextBold
                              : whiteText,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 20,
                  width: 200,
                  color: Colors.blueAccent.withAlpha(128),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      for (final team in matchSchedule.blue)
                        Row(
                          children: [
                            FRCTeamAvatar(teamNumber: team),
                            const SizedBox(width: 2),
                            Text("$team", style: whiteText),
                          ],
                        ),
                      SizedBox(
                        width: 25,
                        child: Text(
                          results?.blueScore != null
                              ? results!.blueScore.toString()
                              : "-",
                          style:
                              results?.winner == Alliance.blue ||
                                  results?.winner == Alliance.tie
                              ? whiteTextBold
                              : whiteText,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
