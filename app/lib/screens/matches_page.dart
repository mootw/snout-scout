import 'package:app/durationformat.dart';
import 'package:app/main.dart';
import 'package:app/match_card.dart';
import 'package:app/screens/edit_schedule.dart';
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
  final ScrollController _controller = ScrollController();

  @override
  void initState() {
    super.initState();

    //Scroll to the next match automatically if it is not null.
    SnoutScoutData data = context.read<SnoutScoutData>();
    final nextMatch = data.db.nextMatch;
    if (nextMatch != null) {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        _controller.jumpTo(data.db.matches.values.toList().indexOf(nextMatch) *
            matchCardHeight);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SnoutScoutData>(builder: (context, snoutData, child) {
      FRCMatch? nextMatch = snoutData.db.nextMatch;
      FRCMatch? teamNextMatch =
          snoutData.db.nextMatchForTeam(snoutData.db.config.team);
      Duration? scheduleDelay = snoutData.db.scheduleDelay;
      return Column(
        children: [
          Expanded(
            child: ListView(
              controller: _controller,
              children: [
                for (var match in snoutData.db.matches.values)
                  MatchCard(match: match, focusTeam: snoutData.db.config.team),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Center(
                    child: FilledButton.tonal(
                        onPressed: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditSchedulePage(
                                    matches: snoutData.db.matches),
                              ));
                        },
                        child: const Text("Edit Schedule")),
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
                                      builder: (context) => MatchPage(
                                          matchid: snoutData.db
                                              .matchIDFromMatch(nextMatch))),
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
                                      builder: (context) => MatchPage(
                                          matchid: snoutData.db
                                              .matchIDFromMatch(
                                                  teamNextMatch))),
                                );
                              },
                              child: Text(
                                teamNextMatch.description,
                                style: TextStyle(
                                    color: teamNextMatch.getAllianceOf(
                                                snoutData.db.config.team) ==
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
