import 'package:app/durationformat.dart';
import 'package:app/providers/data_provider.dart';
import 'package:app/helpers.dart';
import 'package:app/widgets/match_card.dart';
import 'package:app/screens/edit_schedule.dart';
import 'package:app/screens/match_page.dart';
import 'package:app/widgets/timeduration.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:snout_db/event/match.dart';

class AllMatchesPage extends StatefulWidget {
  const AllMatchesPage({super.key});

  @override
  State<AllMatchesPage> createState() => _AllMatchesPageState();
}

class _AllMatchesPageState extends State<AllMatchesPage> {
  final ScrollController _controller = ScrollController();

  @override
  void initState() {
    super.initState();

    //Scroll to the next match with an offset automatically if it is not null.
    DataProvider data = context.read<DataProvider>();
    final nextMatch = data.db.nextMatch;
    if (nextMatch != null) {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        _controller.positions.first.moveTo(
            (data.db.matches.values.toList().indexOf(nextMatch) *
                matchCardHeight) - (matchCardHeight * 2),
            clamp: true);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final snoutData = context.watch<DataProvider>();
    FRCMatch? teamNextMatch =
        snoutData.db.nextMatchForTeam(snoutData.db.config.team);
    Duration? scheduleDelay = snoutData.db.scheduleDelay;
    return Column(
      children: [
        Expanded(
          child:
              // TODO eventually figure out the best performant way to do this.
              // i honeslty thing the lag on the web version might just be
              // due to javascript being slow rather than building being such
              // maybe see what changes after wasm runtime works???????????
              // ListView.builder(
              //     controller: _controller,
              //     itemCount: snoutData.db.matches.values.toList().length,
              //     itemBuilder: (context, index) {
              //       final match = snoutData.db.matches.values.toList()[index];

              //       return Container(
              //           color: match == snoutData.db.nextMatch
              //               ? Theme.of(context).colorScheme.onPrimary
              //               : (match.hasTeam(snoutData.db.config.team)
              //                   ? Theme.of(context).colorScheme.onSecondary
              //                   : null),
              //           child: MatchCard(
              //               match: match, focusTeam: snoutData.db.config.team));
              //     }),
              ListView(
            controller: _controller,
            children: [
              //Iterate through all of the matches and add them to the list
              //if a match is equal to the next match; highlight it!
              for (final match in snoutData.db.matches.values)
                Container(
                    color: match == snoutData.db.nextMatch
                        ? Theme.of(context).colorScheme.onPrimary
                        : (match.hasTeam(snoutData.db.config.team)
                            ? Theme.of(context).colorScheme.onSecondary
                            : null),
                    child: MatchCard(
                        match: match, focusTeam: snoutData.db.config.team)),

                    Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: FilledButton.tonal(
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              EditSchedulePage(matches: snoutData.db.matches),
                        ));
                  },
                  child: const Text("Edit Schedule")),
            ),
          ),
            ],
          ),
        ),
        if (teamNextMatch != null && scheduleDelay != null)
          Container(
            color: Theme.of(context).colorScheme.surfaceVariant,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("delay ${offsetDurationInMins(scheduleDelay)}"),
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => MatchPage(
                                matchid: snoutData.db
                                    .matchIDFromMatch(teamNextMatch))),
                      ),
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
              ],
            ),
          )
      ],
    );
  }
}
