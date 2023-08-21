import 'package:app/providers/data_provider.dart';
import 'package:app/timeduration.dart';
import 'package:provider/provider.dart';
import 'package:app/screens/match_page.dart';
import 'package:flutter/material.dart';
import 'package:snout_db/event/match.dart';
import 'package:snout_db/snout_db.dart';

const double matchCardHeight = 50;

const TextStyle whiteText = TextStyle(color: Colors.white, fontSize: 12);
const TextStyle whiteTextBold =
    TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12);

class MatchCard extends StatelessWidget {
  final FRCMatch match;
  final int? focusTeam;

  const MatchCard({super.key, required this.match, this.focusTeam});

  @override
  Widget build(BuildContext context) {
    final snoutData = context.watch<DataProvider>();
    return SizedBox(
      height: matchCardHeight,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  MatchPage(matchid: snoutData.db.matchIDFromMatch(match))),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
                // width: 120,
                child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(match.description, textAlign: TextAlign.center),
                TimeDuration(
                    time: match.results != null
                        ? match.results!.time
                        : match.scheduledTime),
              ],
            )),
            // const SizedBox(width: 8),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: 22,
                  width: 169,
                  color: Colors.red,
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        for (final team in match.red)
                          Text("$team",
                              style: focusTeam == team
                                  ? whiteTextBold
                                  : whiteText),
                        SizedBox(
                          width: 25,
                          child: Text(
                            match.results?.redScore != null
                                ? match.results!.redScore.toString()
                                : "???",
                            style: match.results?.winner == Alliance.red ||
                                    match.results?.winner == Alliance.tie
                                ? whiteTextBold
                                : whiteText,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ]),
                ),
                Container(
                  height: 22,
                  width: 169,
                  color: Colors.blueAccent,
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        for (final team in match.blue)
                          Text("$team",
                              style: focusTeam == team
                                  ? whiteTextBold
                                  : whiteText),
                        SizedBox(
                          width: 25,
                          child: Text(
                            match.results?.blueScore != null
                                ? match.results!.blueScore.toString()
                                : "???",
                            style: match.results?.winner == Alliance.blue ||
                                    match.results?.winner == Alliance.tie
                                ? whiteTextBold
                                : whiteText,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ]),
                ),
              ],
            ),
            const SizedBox(width: 24),
          ],
        ),
      ),
    );
  }
}
