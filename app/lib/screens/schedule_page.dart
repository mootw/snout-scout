import 'package:app/durationformat.dart';
import 'package:app/providers/data_provider.dart';
import 'package:app/style.dart';
import 'package:app/widgets/match_card.dart';
import 'package:app/screens/edit_schedule.dart';
import 'package:app/screens/match_page.dart';
import 'package:app/widgets/timeduration.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:snout_db/event/match_schedule_item.dart';

class AllMatchesPage extends StatefulWidget {
  final double? scrollPosition;

  const AllMatchesPage({super.key, this.scrollPosition});

  @override
  State<AllMatchesPage> createState() => _AllMatchesPageState();
}

class _AllMatchesPageState extends State<AllMatchesPage> {
  late ScrollController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        ScrollController(initialScrollOffset: widget.scrollPosition ?? 0);
  }

  @override
  Widget build(BuildContext context) {
    final snoutData = context.watch<DataProvider>();

    MatchScheduleItem? teamNextMatch =
        snoutData.event.nextMatchForTeam(snoutData.event.config.team);
    Duration? scheduleDelay = snoutData.event.scheduleDelay;
    return Column(
      children: [
        Expanded(
          child: ListView(
            controller: _controller,
            children: [
              //Iterate through all of the matches and add them to the list
              //if a match is equal to the next match; highlight it!
              for (final matchSchedule in snoutData.event.scheduleSorted)
                Container(
                    color: matchSchedule == snoutData.event.nextMatch
                        ? Theme.of(context).colorScheme.onPrimary
                        : null,
                    child: MatchCard(
                        match: matchSchedule.getData(snoutData.event),
                        matchSchedule: matchSchedule,
                        focusTeam: snoutData.event.config.team)),

              Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: FilledButton.tonal(
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditSchedulePage(
                                  matches: snoutData.event.schedule),
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
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Schedule ${offsetDurationInMins(scheduleDelay)}"),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            MatchPage(matchid: teamNextMatch.id)),
                  ),
                  child: Text(
                    teamNextMatch.label,
                    style: TextStyle(
                        color: getAllianceUIColor(teamNextMatch
                            .getAllianceOf(snoutData.event.config.team))),
                  ),
                ),
                TimeDuration(
                    time: teamNextMatch.scheduledTime.add(scheduleDelay),
                    displayDurationDefault: true),
              ],
            ),
          )
      ],
    );
  }
}
