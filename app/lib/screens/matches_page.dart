import 'package:app/durationformat.dart';
import 'package:app/main.dart';
import 'package:app/match_card.dart';
import 'package:app/screens/match_page.dart';
import 'package:app/timeduration.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:snout_db/event/match.dart';
import 'package:snout_db/snout_db.dart';

class AllMatchesPage extends StatefulWidget {
  const AllMatchesPage({Key? key}) : super(key: key);

  @override
  State<AllMatchesPage> createState() => _AllMatchesPageState();
}

class _AllMatchesPageState extends State<AllMatchesPage> {
  @override
  Widget build(BuildContext context) {
    return Consumer<SnoutScoutData>(builder: (context, snoutData, child) {
      FRCMatch? nextMatch = snoutData.currentEvent.nextMatch;
      FRCMatch? teamNextMatch =
          snoutData.currentEvent.nextMatchForTeam(snoutData.season.team);
      Duration? scheduleDelay = snoutData.currentEvent.scheduleDelay;
      return Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                for (var match in snoutData.currentEvent.matches)
                  MatchCard(match: match, focusTeam: snoutData.season.team),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Center(
                    child: FilledButton.tonal(
                        onPressed: () {}, child: const Text("Edit Schedule")),
                  ),
                )
              ],
            ),
          ),
          if (nextMatch != null &&
              teamNextMatch != null &&
              scheduleDelay != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  Text("Schedule Delay: ${offsetDurationInMins(scheduleDelay)}",
                      style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 4),
                  Table(
                    children: [
                      TableRow(children: [
                        Center(
                            child: Text("Next Match",
                                style: Theme.of(context).textTheme.titleSmall)),
                        const Center(child: Text("Your Next Match")),
                      ]),
                      TableRow(children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          MatchPage(matchid: snoutData.currentEvent.matches.indexOf(nextMatch))),
                                );
                              },
                              child: Text(nextMatch.description),
                            ),
                            TimeDuration(
                                time:
                                    nextMatch.scheduledTime.add(scheduleDelay),
                                displayDurationDefault: true),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          MatchPage(matchid: snoutData.currentEvent.matches.indexOf(teamNextMatch))),
                                );
                              },
                              child: Text(
                                teamNextMatch.description,
                                style: TextStyle(
                                    color: teamNextMatch.getAllianceOf(
                                                snoutData.season.team) ==
                                            Alliance.red
                                        ? Colors.red
                                        : Colors.blue),
                              ),
                            ),
                            TimeDuration(
                                time: teamNextMatch.scheduledTime
                                    .add(scheduleDelay),
                                displayDurationDefault: true),
                          ],
                        ),
                      ]),
                    ],
                  ),
                ],
              ),
            )
        ],
      );
    });
  }
}
