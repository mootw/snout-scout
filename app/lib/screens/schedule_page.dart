import 'package:app/durationformat.dart';
import 'package:app/providers/data_provider.dart';
import 'package:app/widgets/match_card.dart';
import 'package:app/screens/edit_schedule.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:snout_db/event/frcevent.dart';
import 'package:snout_db/event/match_schedule_item.dart';

class AllMatchesPage extends StatefulWidget {
  final MatchScheduleItem? scrollPosition;

  const AllMatchesPage({super.key, this.scrollPosition});

  @override
  State<AllMatchesPage> createState() => _AllMatchesPageState();
}

class _AllMatchesPageState extends State<AllMatchesPage> {
  late ScrollController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ScrollController(
      initialScrollOffset: widget.scrollPosition == null
          ? 0
          : (context.read<DataProvider>().event.scheduleSorted.indexOf(
                      widget.scrollPosition!,
                    ) *
                    matchCardHeight) -
                (matchCardHeight * 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    final snoutData = context.watch<DataProvider>();
    return ListView(
      controller: _controller,
      children: [
        for (final (idx, matchSchedule)
            in snoutData.event.scheduleSorted.indexed)
        // TODO correctly handle breaks in the list in the inital scroll position check
        ...[
          if (idx > 0 &&
              matchSchedule.scheduledTime.difference(
                    snoutData.event.scheduleSorted[idx - 1].scheduledTime,
                  ) >
                  scheduleBreakDuration)
            Center(
              child: Text(
                '${formatDurationLength(matchSchedule.scheduledTime.difference(snoutData.event.scheduleSorted[idx - 1].scheduledTime))} break',
              ),
            ),
          Container(
            color: matchSchedule == snoutData.event.nextMatch
                ? Theme.of(context).colorScheme.onPrimary
                : null,
            child: MatchCard(
              match: matchSchedule.getData(snoutData.event),
              results: snoutData.event.getMatchResults(matchSchedule.id),
              matchSchedule: matchSchedule,
              focusTeam: snoutData.event.config.team,
            ),
          ),
        ],
    
        Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: FilledButton.tonal(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditSchedulePage(
                      matches: snoutData.event.schedule,
                    ),
                  ),
                );
              },
              child: const Text("Edit Schedule"),
            ),
          ),
        ),
      ],
    );
  }
}
