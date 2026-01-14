import 'dart:async';

import 'package:app/battle_pass/battle_pass.dart';
import 'package:app/durationformat.dart';
import 'package:app/providers/data_provider.dart';
import 'package:app/screens/documentation_page.dart';
import 'package:app/screens/edit_data_items.dart';
import 'package:app/screens/scout_leaderboard.dart';
import 'package:app/screens/teams_page.dart';
import 'package:app/screens/view_team_page.dart';
import 'package:app/widgets/edit_audit.dart';
import 'package:app/widgets/match_card.dart';
import 'package:app/widgets/scout_status.dart';
import 'package:app/widgets/timeduration.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:snout_db/data_item.dart';
import 'package:snout_db/event/match_schedule_item.dart';
import 'package:url_launcher/url_launcher_string.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late Timer _updateTimer;

  @override
  void initState() {
    _updateTimer = Timer.periodic(
      Duration(seconds: 5),
      (_) => setState(() {
        // TODO actually make the home page update nicely on its own. This is mostly for any counters and timers.
      }),
    );
    super.initState();
  }

  @override
  void dispose() {
    _updateTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final snoutData = context.watch<DataProvider>();
    final tbaKey = snoutData.event.config.tbaEventId;

    Duration? scheduleDelay = snoutData.event.scheduleDelay;

    MatchScheduleItem? teamNextMatch = snoutData.event.nextMatchForTeam(
      snoutData.event.config.team,
    );

    final nextMatch = snoutData.event.nextMatch;

    final numberOfRecordedMatchesByTeam = snoutData.event.teams
        .map(
          (team) =>
              MapEntry(team, snoutData.event.teamRecordedMatches(team).length),
        )
        // Lowest to highest
        .sorted((a, b) => a.value.compareTo(b.value));

    final teamsWithInsufficientMatchRecordings = numberOfRecordedMatchesByTeam
        .where(
          (entry) =>
              entry.value <
              snoutData.event
                      .matcheScheduledWithTeam(entry.key)
                      .where((match) => match.isComplete(snoutData.event))
                      .length *
                  0.5,
        );

    final numberOfPitScoutingItemsByTeam = snoutData.event.teams
        .map(
          (team) => MapEntry(
            team,
            snoutData.event.pitscouting[team.toString()]?.length ?? 0,
          ),
        )
        // Lowest to highest
        .sorted((a, b) => a.value.compareTo(b.value));

    final teamsWithInsufficientPitData = numberOfPitScoutingItemsByTeam.where(
      (entry) => entry.value < snoutData.event.config.pitscouting.length * 0.5,
    );

    return ListView(
      cacheExtent: 5000,
      children: [
        Wrap(
          children: [
            if (tbaKey != null)
              TextButton(
                onPressed: () => launchUrlString(
                  "https://www.thebluealliance.com/event/$tbaKey#rankings",
                ),
                child: const Text("TBA"),
              ),
            IconButton(
              icon: Image.asset(
                'assets/battle_pass.png',
                width: 24,
                height: 24,
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BattlePassPage()),
              ),
            ),
            IconButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DocumentationScreen(),
                ),
              ),
              icon: Icon(Icons.book),
            ),
            // IconButton(
            //   icon: Icon(Icons.trending_up),
            //   onPressed: () => Navigator.push(
            //     context,
            //     MaterialPageRoute(builder: (context) => const BattlePassPage()),
            //   ),
            // ),
          ],
        ),

        Divider(),

        // Upcoming match
        Text(
          "Schedule ${scheduleDelay == null ? "unknown" : offsetDurationInMins(scheduleDelay)}",
          style: Theme.of(context).textTheme.titleLarge,
        ),

        if (nextMatch != null)
          MatchCard(
            match: nextMatch.getData(snoutData.event),
            results: snoutData.event.getMatchResults(nextMatch.id),
            matchSchedule: nextMatch,
            focusTeam: snoutData.event.config.team,
          ),

        const SizedBox(height: 16),

        Text("Our Next Match", style: Theme.of(context).textTheme.titleLarge),
        if (teamNextMatch != null && scheduleDelay != null)
          Row(
            children: [
              Text("Our next match "),
              TimeDuration(
                time: teamNextMatch.scheduledTime.add(scheduleDelay),
                displayDurationDefault: true,
              ),
            ],
          ),
        if (teamNextMatch != null)
          MatchCard(
            match: teamNextMatch.getData(snoutData.event),
            results: snoutData.event.getMatchResults(teamNextMatch.id),
            matchSchedule: teamNextMatch,
            focusTeam: snoutData.event.config.team,
          ),

        const SizedBox(height: 16),

        Divider(),

        Text(
          "Teams with sufficient pit scouting information (${snoutData.event.teams.length - teamsWithInsufficientPitData.length}/${snoutData.event.teams.length})",
          style: Theme.of(context).textTheme.titleLarge,
        ),
        if (teamsWithInsufficientPitData.isEmpty)
          Text("All teams are sufficient :)"),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            spacing: 8,
            children: [
              for (final team in teamsWithInsufficientPitData)
                TeamListTile(
                  teamNumber: team.key,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            TeamViewPage(teamNumber: team.key),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        Text(
          "Teams with sufficient match recordings (${snoutData.event.teams.length - teamsWithInsufficientMatchRecordings.length}/${snoutData.event.teams.length})",
          style: Theme.of(context).textTheme.titleLarge,
        ),
        if (teamsWithInsufficientMatchRecordings.isEmpty)
          Text("All teams are sufficient :)"),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            spacing: 8,
            children: [
              for (final team in teamsWithInsufficientMatchRecordings)
                TeamListTile(
                  teamNumber: team.key,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            TeamViewPage(teamNumber: team.key),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),

        Divider(),

        Center(
          child: FilledButton(
            onPressed: () async {
              await editPitData(context);
            },
            child: Text('Edit Pit Data'),
          ),
        ),
        Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 800),
            child: Column(
              children: [
                for (final item in snoutData.event.config.pit) ...[
                  DynamicValueViewer(
                    itemType: item,
                    value: snoutData.event.pitDataItems()?[item.id],
                  ),
                  Container(
                    padding: const EdgeInsets.only(right: 16),
                    alignment: Alignment.centerRight,
                    child: DataItemEditAudit(
                      dataItem: DataItem.pit(item.id, null),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        Divider(),

        Text(
          "Recent Scout Activities",
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const ScoutStatus(),

        const SizedBox(height: 16),

        Text("Leaderboard", style: Theme.of(context).textTheme.titleLarge),
        ScoutLeaderboard(),

        const SizedBox(height: 16),
      ],
    );
  }
}
