import 'package:app/main.dart';
import 'package:app/timeduration.dart';
import 'package:provider/provider.dart';
import 'package:app/screens/match_page.dart';
import 'package:app/screens/view_team_page.dart';
import 'package:flutter/material.dart';
import 'package:snout_db/event/match.dart';
import 'package:snout_db/snout_db.dart';

const double matchCardHeight = 60;

const TextStyle whiteText = TextStyle(color: Colors.white70, fontSize: 13);
const TextStyle whiteTextBold =
    TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13);

class MatchCard extends StatelessWidget {
  final FRCMatch match;
  final int? focusTeam;

  const MatchCard({Key? key, required this.match, this.focusTeam})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final snoutData = context.watch<EventDB>();
    return SizedBox(
      height: matchCardHeight,
      child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      MatchPage(matchid: snoutData.db.matchIDFromMatch(match))),
            );
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 130,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(match.description,
                        textAlign: TextAlign.center),
                    if (match.results != null)
                      TimeDuration(time: match.results!.time),
                    if (match.results == null)
                      TimeDuration(time: match.scheduledTime),
                  ],
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: 28,
                    width: 190,
                    color: Colors.redAccent,
                    child: Row(children: [
                      for (final team in match.red)
                        TextButton(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              minimumSize: const Size(0, 30),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        TeamViewPage(teamNumber: team)),
                              );
                            },
                            child: Text("$team",
                                style: focusTeam == team
                                    ? whiteTextBold
                                    : whiteText)),
                      Container(
                        alignment: Alignment.center,
                        width: 42,
                        child: Text(
                          match.results?.red['points'] != null
                              ? match.results!.red['points'].toString()
                              : "?",
                          style: match.results?.winner == Alliance.red ||
                                  match.results?.winner == Alliance.tie
                              ? whiteTextBold : null,
                        ),
                      ),
                    ]),
                  ),
                  Container(
                    height: 28,
                    width: 190,
                    color: Colors.blueAccent,
                    child: Row(
                      children: [
                      for (final team in match.blue)
                        TextButton(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              minimumSize: const Size(0, 30),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        TeamViewPage(teamNumber: team)),
                              );
                            },
                            child: Text("$team",
                                style: focusTeam == team
                                    ? whiteTextBold
                                    : whiteText)),
                      Container(
                        alignment: Alignment.center,
                        width: 42,
                        child: Text(
                            match.results?.blue['points'] != null
                                ? match.results!.blue['points'].toString()
                                : "?",
                            style: match.results?.winner == Alliance.blue ||
                                    match.results?.winner == Alliance.tie
                                ? whiteTextBold
                                : null),
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
