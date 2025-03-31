import 'package:app/providers/data_provider.dart';
import 'package:app/style.dart';
import 'package:app/widgets/timeduration.dart';
import 'package:provider/provider.dart';
import 'package:app/screens/match_page.dart';
import 'package:flutter/material.dart';
import 'package:snout_db/event/match_data.dart';
import 'package:snout_db/event/match_schedule_item.dart';
import 'package:snout_db/snout_db.dart';

const double matchCardHeight = 46;

const TextStyle whiteText = TextStyle(color: Colors.white, fontSize: 12);
const TextStyle whiteTextBold = TextStyle(
  color: Colors.white,
  fontWeight: FontWeight.bold,
  fontSize: 12,
);

class MatchCard extends StatelessWidget {
  final MatchData? match;
  final MatchScheduleItem matchSchedule;
  final int? focusTeam;

  const MatchCard({
    super.key,
    required this.match,
    required this.matchSchedule,
    this.focusTeam,
  });

  @override
  Widget build(BuildContext context) {
    final snoutData = context.watch<DataProvider>();
    return SizedBox(
      height: matchCardHeight,
      child: InkWell(
        onTap:
            () => Navigator.push(
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
              child: TimeDuration(
                time:
                    match?.results != null
                        ? match!.results!.time
                        : matchSchedule.scheduledTime.add(
                          snoutData.event.scheduleDelay ?? Duration.zero,
                        ),
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
              width: 110,
              child: Text(matchSchedule.label, textAlign: TextAlign.center),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: 20,
                  width: 160,
                  color: Colors.red,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      for (final team in matchSchedule.red)
                        Text("$team", style: whiteText),
                      SizedBox(
                        width: 25,
                        child: Text(
                          match?.results?.redScore != null
                              ? match!.results!.redScore.toString()
                              : "-",
                          style:
                              match?.results?.winner == Alliance.red ||
                                      match?.results?.winner == Alliance.tie
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
                  width: 160,
                  color: Colors.blueAccent,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      for (final team in matchSchedule.blue)
                        Text("$team", style: whiteText),
                      SizedBox(
                        width: 25,
                        child: Text(
                          match?.results?.blueScore != null
                              ? match!.results!.blueScore.toString()
                              : "-",
                          style:
                              match?.results?.winner == Alliance.blue ||
                                      match?.results?.winner == Alliance.tie
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
