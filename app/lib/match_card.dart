import 'package:app/main.dart';
import 'package:app/timeduration.dart';
import 'package:provider/provider.dart';
import 'package:app/screens/match_page.dart';
import 'package:app/screens/view_team_page.dart';
import 'package:flutter/material.dart';
import 'package:snout_db/event/match.dart';
import 'package:snout_db/snout_db.dart';

const TextStyle whiteText = TextStyle(color: Colors.white70);
const TextStyle whiteTextBold =
    TextStyle(color: Colors.white, fontWeight: FontWeight.bold);

class MatchCard extends StatelessWidget {
  final FRCMatch match;
  final int? focusTeam;

  const MatchCard({Key? key, required this.match, this.focusTeam})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<SnoutScoutData>(
      builder: (context, snoutData, child) {

        return Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 4),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => MatchPage(
                        matchid: snoutData.db.matchIDFromMatch(match))),
              );
            },
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 120,
                    child: Column(
                      children: [
                        Text(match.description,
                            style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                        if (match.results != null)
                          TimeDuration(time: match.results!.time),
                        if (match.results == null)
                          TimeDuration(time: match.scheduledTime),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      Container(
                        color: Colors.red,
                        child: Row(children: [
                          for (var team in match.red)
                            TextButton(
                                style: TextButton.styleFrom(
                                  minimumSize: const Size(0, 42),
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
                                  ? whiteTextBold
                                  : whiteText,
                            ),
                          ),
                        ]),
                      ),
                      Container(
                        color: Colors.blue,
                        child: Row(children: [
                          for (var team in match.blue)
                            TextButton(
                                style: TextButton.styleFrom(
                                  minimumSize: const Size(0, 42),
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
                                    : whiteText),
                          ),
                        ]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      }
    );
  }
}
