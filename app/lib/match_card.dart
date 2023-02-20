import 'package:app/main.dart';
import 'package:app/timeduration.dart';
import 'package:provider/provider.dart';
import 'package:app/screens/match_page.dart';
import 'package:app/screens/view_team_page.dart';
import 'package:flutter/material.dart';
import 'package:snout_db/event/match.dart';
import 'package:snout_db/snout_db.dart';

const double matchCardHeight = 69;

const TextStyle whiteText = TextStyle(color: Colors.white70, fontSize: 12);
const TextStyle whiteTextBold =
    TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12);

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
                width: 120,
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
                    height: 33,
                    color: Colors.red,
                    child: Row(children: [
                      for (var team in match.red)
                        TextButton(
                            style: TextButton.styleFrom(
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
                        width: 52,
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
                    height: 33,
                    color: Colors.blue,
                    child: Row(children: [
                      for (var team in match.blue)
                        TextButton(
                            style: TextButton.styleFrom(
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
                        width: 52,
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
