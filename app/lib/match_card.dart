import 'package:app/eventdb_state.dart';
import 'package:app/timeduration.dart';
import 'package:provider/provider.dart';
import 'package:app/screens/match_page.dart';
import 'package:flutter/material.dart';
import 'package:snout_db/event/match.dart';
import 'package:snout_db/snout_db.dart';

const double matchCardHeight = 48;

const TextStyle whiteText = TextStyle(color: Colors.white, fontSize: 12);
const TextStyle whiteTextBold =
    TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12);

class MatchCard extends StatelessWidget {
  final FRCMatch match;
  final int? focusTeam;

  const MatchCard({super.key, required this.match, this.focusTeam});

  @override
  Widget build(BuildContext context) {
    final snoutData = context.watch<EventDB>();
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
            SizedBox(
                width: 120,
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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: 25,
                  width: 150,
                  color: Colors.redAccent,
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        for (final team in match.red)
                          Text("$team",
                                  style: focusTeam == team
                                      ? whiteTextBold
                                      : whiteText),
                        Container(
                  color: Colors.red,
                          width: 32,
                          child: Text(
                            match.results?.red['points'] != null
                                ? match.results!.red['points'].toString()
                                : "?",
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
                  height: 25,
                  width: 150,
                  color: Colors.blueAccent,
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        for (final team in match.blue)
                          Text("$team",
                                  style: focusTeam == team
                                      ? whiteTextBold
                                      : whiteText),
                        Container(
  color: Colors.blue,
                          width: 32,
                          child: Text(
                            match.results?.blue['points'] != null
                                ? match.results!.blue['points'].toString()
                                : "?",
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
          ],
        ),
      ),
    );
  }
}
