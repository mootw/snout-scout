import 'package:app/durationformat.dart';
import 'package:app/helpers.dart';
import 'package:app/main.dart';
import 'package:app/match_card.dart';
import 'package:app/screens/match_page.dart';
import 'package:app/timeduration.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:snout_db/event/match.dart';

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
    EventDB data = context.read<EventDB>();
    final nextMatch = data.db.nextMatch;
    if (nextMatch != null) {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
          _controller.positions.first.moveTo(
            data.db.matches.values.toList().indexOf(nextMatch) *
                matchCardHeight,
            clamp: true);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final snoutData = context.watch<EventDB>();
    FRCMatch? teamNextMatch =
        snoutData.db.nextMatchForTeam(snoutData.db.config.team);
    Duration? scheduleDelay = snoutData.db.scheduleDelay;
    return Column(
      children: [
        Expanded(
          child: ListView(
            controller: _controller,
            children: [
              //Iterate through all of the matches and add them to the list
              //if a match is equal to the next match; highlight it!
              for (final match in snoutData.db.matches.values)
                Container(
                    color: match == snoutData.db.nextMatch
                        ? Theme.of(context).colorScheme.onPrimary
                        : null,
                    child: MatchCard(
                        match: match, focusTeam: snoutData.db.config.team)),
            ],
          ),
        ),
        if (teamNextMatch != null && scheduleDelay != null)
          Container(
            color: Theme.of(context).colorScheme.surfaceVariant,
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Center(child: Text("Next Match")),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => MatchPage(
                                  matchid: snoutData.db
                                      .matchIDFromMatch(teamNextMatch))),
                        );
                      },
                      child: Text(
                        teamNextMatch.description,
                        style: TextStyle(
                            color: getAllianceColor(teamNextMatch
                                .getAllianceOf(snoutData.db.config.team))),
                      ),
                    ),
                    TimeDuration(
                        time: teamNextMatch.scheduledTime.add(scheduleDelay),
                        displayDurationDefault: true),
                  ],
                ),
                Text("delay: ${offsetDurationInMins(scheduleDelay)}"),
              ],
            ),
          )
      ],
    );
  }
}
