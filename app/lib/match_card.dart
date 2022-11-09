import 'package:app/main.dart';
import 'package:app/timeduration.dart';
import 'package:provider/provider.dart';
import 'package:snout_db/event/match.dart';
import 'package:app/screens/match_page.dart';
import 'package:app/screens/view_team_page.dart';
import 'package:flutter/material.dart';

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
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 4),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => MatchPage(
                    matchid: Provider.of<SnoutScoutData>(context, listen: false)
                        .currentEvent
                        .matches
                        .indexOf(match))),
          );
        },
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 140,
                child: Column(
                  children: [
                    Text(match.description,
                        style: TextStyle(fontWeight: FontWeight.bold)),
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
                              minimumSize: Size(0, 42),
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
                          style: match.results?.winner == "red" ||
                                  match.results?.winner == "tie"
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
                              minimumSize: Size(0, 42),
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
                            style: match.results?.winner == "blue" ||
                                    match.results?.winner == "tie"
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
}
