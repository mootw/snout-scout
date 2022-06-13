import 'package:app/data/matches.dart';
import 'package:app/screens/match_page.dart';
import 'package:app/screens/view_team_page.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

const TextStyle whiteText = TextStyle(color: Colors.white70);
const TextStyle whiteTextBold =
    TextStyle(color: Colors.white, decoration: TextDecoration.underline);

class MatchCard extends StatelessWidget {
  final Match match;
  final int? focusTeam;

  const MatchCard({Key? key, required this.match, this.focusTeam})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => MatchPage(match: match)),
          );
        },
        child: Column(
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                SizedBox(
                  width: 96,
                  child: Column(
                    children: [
                      Text("${match.section} ${match.number}"),
                      Text(
                          "${DateFormat.jm().format(DateTime.parse(match.scheduledTime).toLocal())}"),
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
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          TeamViewPage(number: team)),
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
                            match.results?.red.values['points'] != null ? match.results!.red.values['points'].toString() : "?",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                        ),
                      ]),
                    ),
                    Container(
                      color: Colors.blue,
                      child: Row(children: [
                        for (var team in match.blue)
                          TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          TeamViewPage(number: team)),
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
                            match.results?.blue.values['points'] != null ? match.results!.blue.values['points'].toString() : "?",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                        ),
                      ]),
                    ),
                  ],
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
