import 'dart:async';

import 'package:app/durationformat.dart';
import 'package:app/providers/data_provider.dart';
import 'package:app/screens/scout_leaderboard.dart';
import 'package:app/screens/teams_page.dart';
import 'package:app/widgets/match_card.dart';
import 'package:app/widgets/scout_status.dart';
import 'package:app/widgets/timeduration.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:snout_db/event/match_schedule_item.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {

  late Timer _updateTimer;

  @override void initState() {
    _updateTimer = Timer.periodic(Duration(seconds: 5), (_) => setState(() {
      // TODO actually make the home page update nicely on its own. This is mostly for any counters and timers.
    }));
    super.initState();
  }

  @override
  void dispose () {
    _updateTimer.cancel();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final snoutData = context.watch<DataProvider>();

    Duration? scheduleDelay = snoutData.event.scheduleDelay;

    MatchScheduleItem? teamNextMatch = snoutData.event.nextMatchForTeam(
      snoutData.event.config.team,
    );

    final nextMatch = snoutData.event.nextMatch;

    final teamsInUpcomingMatches =
        snoutData.event
            .matchesWithTeam(snoutData.event.config.team)
            .reversed
            .where((match) => match.isComplete(snoutData.event) == false)
            .fold(<int>[], (last, next) => [...last, ...next.blue, ...next.red])
            // Do not include our team
            .where((team) => team != snoutData.event.config.team)
            .toSet();

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
                      .matchesWithTeam(entry.key)
                      .where((match) => match.isComplete(snoutData.event))
                      .length *
                  0.5,
        );

    final numberOfPitScoutingItemsByTeam = snoutData.event.pitscouting.entries
        .map((e) => MapEntry(e.key, e.value.length))
        // Lowest to highest
        .sorted((a, b) => a.value.compareTo(b.value));

    final teamsWithInsufficientPitData = numberOfPitScoutingItemsByTeam.where(
      (entry) => entry.value < snoutData.event.config.pitscouting.length * 0.5,
    );

    return ListView(
      children: [
        // Upcoming match
        Text(
          "Schedule Delay: ${scheduleDelay == null ? "unknown" : offsetDurationInMins(scheduleDelay)}",
        ),
        Text("Next Match"),
        if (nextMatch != null)
          MatchCard(
            match: nextMatch.getData(snoutData.event),
            matchSchedule: nextMatch,
            focusTeam: snoutData.event.config.team,
          ),

        Text("Our Next Match"),
        if (teamNextMatch != null)
          MatchCard(
            match: teamNextMatch.getData(snoutData.event),
            matchSchedule: teamNextMatch,
            focusTeam: snoutData.event.config.team,
          ),

        if (teamNextMatch != null && scheduleDelay != null)
          Row(
            children: [
              Text("Our next match: "),
              TimeDuration(
                time: teamNextMatch.scheduledTime.add(scheduleDelay),
                displayDurationDefault: true,
              ),
            ],
          ),

        Text("Teams marked as needing help"),

        Divider(),

        Text("Teams To Scout"),

        Text("Teams in our upcoming matches"),
        if (teamsInUpcomingMatches.isEmpty) Text("No teams"),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            spacing: 8,
            children: [
              for (final team in teamsInUpcomingMatches)
                TeamListTile(teamNumber: team),
            ],
          ),
        ),

        Text(
          "Team with insufficient pit scouting information (${teamsWithInsufficientPitData.length}/${snoutData.event.teams.length})",
        ),
        if (teamsWithInsufficientPitData.isEmpty)
          Text("All teams are sufficient :)"),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            spacing: 8,
            children: [
              for (final team in teamsWithInsufficientPitData)
                TeamListTile(teamNumber: int.tryParse(team.key) ?? 0),
            ],
          ),
        ),

        Text(
          "Teams with insufficient match recordings (${teamsWithInsufficientMatchRecordings.length}/${snoutData.event.teams.length})",
        ),
        if (teamsWithInsufficientMatchRecordings.isEmpty)
          Text("All teams are sufficient :)"),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            spacing: 8,
            children: [
              for (final team in teamsWithInsufficientMatchRecordings)
                TeamListTile(teamNumber: team.key),
            ],
          ),
        ),

        Divider(),

        Text("Recent Scout Activities"),
        const ScoutStatus(),

        Text("Leaderboard"),
        ScoutLeaderboard(),

        const SizedBox(height: 16),
      ],
    );
  }
}
