import 'package:collection/collection.dart';
import 'package:decimal/decimal.dart';
import 'package:eval_ex/built_ins.dart';
import 'package:eval_ex/expression.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:snout_db/config/eventconfig.dart';
import 'package:snout_db/config/matchresults_process.dart';
import 'package:snout_db/data_item.dart';
import 'package:snout_db/event/dynamic_property.dart';
import 'package:snout_db/event/match_data.dart';
import 'package:snout_db/event/match_schedule_item.dart';
import 'package:snout_db/event/matchevent.dart';
import 'package:snout_db/event/matchresults.dart';
import 'package:snout_db/event/robot_match_trace.dart';
import 'package:snout_db/pubkey.dart';

part 'frcevent.g.dart';

const scheduleBreakDuration = Duration(minutes: 29);

@JsonSerializable()
class FRCEvent {
  /// how should this event be tracked?
  EventConfig config;

  ///List of teams in the event, ideally ordered smallest number to largest
  List<int> teams;

  /// '''Table''' of data items
  @JsonKey(includeToJson: false, includeFromJson: false)
  Map<String, (DataItem item, Pubkey author, DateTime modifiedDate)> dataItems =
      {};

  /// '''Table'''
  @JsonKey(includeToJson: false, includeFromJson: false)
  Map<String, (RobotMatchTraceData item, Pubkey author, DateTime modifiedDate)>
  traces = {};

  Map<String, MatchScheduleItem> schedule;

  /// '''Table'''
  @JsonKey(includeToJson: false, includeFromJson: false)
  Map<String, (MatchResultValues item, Pubkey author, DateTime modifiedDate)>
  matchResults = {};

  // Sorted schedule. Important for some lookups
  List<MatchScheduleItem> get scheduleSorted => schedule.values.sorted();

  /// --------------------------------------------
  /// EVERYTHING BELOW THIS POINT IS DERIVED DATA
  /// --------------------------------------------

  /// Match Data
  Map<String, MatchData> matches = {};

  MatchResultValues? getMatchResults(String matchId) =>
      matchResults['/match/$matchId/result']?.$1;

  // Legacy-like accessor for match survey data
  DynamicProperties? matchSurvey(int team, String matchId) {
    final f = DynamicProperties.fromEntries(
      dataItems.entries
          .where(
            // TODO use a more robust way to identify the values for this robots survey using a proper index based on the config
            (e) => e.key.startsWith('/match/$matchId/team/$team'),
          )
          .map((e) => MapEntry(e.value.$1.key, e.value.$1.value))
          .toList(),
    );
    return f;
  }

  DynamicProperties? pitData() {
    final f = DynamicProperties.fromEntries(
      dataItems.entries
          .where(
            // TODO use a more robust way to identify the values for this robots survey using a proper index based on the config
            (e) => e.key.startsWith('/pit/'),
          )
          .map((e) => MapEntry(e.value.$1.key, e.value.$1.value))
          .toList(),
    );
    return f;
  }

  DynamicProperties? matchProperties(String matchId) {
    final f = DynamicProperties.fromEntries(
      dataItems.entries
          .where(
            // TODO use a more robust way to identify the values for this robots survey using a proper index based on the config
            (e) => e.key.startsWith('/match/$matchId/data/'),
          )
          .map((e) => MapEntry(e.value.$1.key, e.value.$1.value))
          .toList(),
    );
    return f;
  }

  List<MapEntry<String, MatchData>> matchesSorted() {
    return matches.entries.sorted((a, b) {
      final aValue = a.value.getSchedule(this, a.key);
      final bValue = b.value.getSchedule(this, b.key);

      return aValue == null || bValue == null ? 0 : aValue.compareTo(bValue);
    });
  }

  //Team Survey results TODO JANK implementation and so inefficient it's not even funny
  Map<String, DynamicProperties> get pitscouting {
    final entries = dataItems.entries
        .where((entry) => entry.key.startsWith('/team/'))
        .toList();

    final Map<String, Map<String, dynamic>> result = {};

    for (final entry in entries) {
      // Remove leading slash if present and split
      final parts = entry.key.startsWith('/')
          ? entry.key.substring(1).split('/')
          : entry.key.split('/');

      // Ensure we have the expected structure: team/<id>/<attribute>
      if (parts.length >= 3 && parts[0] == 'team') {
        final teamId = parts[1];
        // Join the rest in case the attribute itself contains slashes
        final attribute = parts.sublist(2).join('/');

        // Get or create the inner map for this team
        final teamMap = result.putIfAbsent(teamId, () => <String, dynamic>{});

        // Add the attribute.
        // If you have a value associated with this key, assign it here.
        // Otherwise, we can set it to null, true, or the original full key.
        teamMap[attribute] = entry.value.$1.value;
      }
    }

    return result;
  }

  //Enforce that all matches are sorted
  FRCEvent({
    required this.config,
    required this.matches,
    this.teams = const [],
    this.schedule = const {},
  });

  factory FRCEvent.fromJson(Map json) => _$FRCEventFromJson(json);
  Map toJson() => _$FRCEventToJson(this);

  /// returns matches SCHEDULED to have a specific team in them.
  /// this is NOT the same as teamRecordedMatches which is all matches
  /// that are actually recorded
  List<MatchScheduleItem> matcheScheduledWithTeam(int team) => scheduleSorted
      .where((match) => match.isScheduledToHaveTeam(team))
      .toList();

  //returns the match after the last match with results
  MatchScheduleItem? get nextMatch => scheduleSorted
      .toList()
      .reversed
      .lastWhereOrNull((match) => match.isComplete(this) == false);

  MatchScheduleItem? nextMatchForTeam(int team) => matcheScheduledWithTeam(
    team,
  ).reversed.lastWhereOrNull((match) => match.isComplete(this) == false);

  //Calculates the schedule delay by using the delay of the last match with results actual time versus the scheduled time.
  Duration? get scheduleDelay {
    final nextMatch = scheduleSorted.lastWhereOrNull(
      (match) => match.isComplete(this),
    );

    final matchAfterNext = nextMatch == null
        ? null
        : scheduleSorted.firstWhereOrNull(
            (match) => match.scheduledTime.isAfter(nextMatch.scheduledTime),
          );

    if (nextMatch != null &&
        matchAfterNext != null &&
        matchAfterNext.scheduledTime.difference(nextMatch.scheduledTime) >
            scheduleBreakDuration) {
      // Assume no schedule delay between matches that have a large time difference (new days and lunch break)
      return Duration.zero;
    }

    return nextMatch?.delayFromScheduledTime(this);
  }

  /// Returns all matches that include a recording for a specific team
  Iterable<MapEntry<String, MatchData>> teamRecordedMatches(int team) => matches
      .entries
      .where((element) => element.value.robot.keys.contains(team.toString()));

  /// Returns the average value of a given metric per match over all recorded matches.
  /// returns null if there is no data. Otherwise we get weird NaN stuff and
  /// if you add NaN to anything it completely destroys the whole calculation
  /// There is an optional where clause to filter the events out for a specific type
  double? teamAverageMetric(
    int team,
    String eventId, [
    bool Function(MatchEvent)? where,
  ]) {
    final recordedMatches = teamRecordedMatches(team);

    if (recordedMatches.isEmpty) {
      //TODO handle this nicer by testing for NaN as well on the fold operation
      return null;
    }

    return recordedMatches.fold<double>(
          0,
          (previousValue, match) =>
              previousValue +
              (match.value.robot[team.toString()]?.timeline
                      .where(
                        (event) =>
                            event.id == eventId && (where?.call(event) ?? true),
                      )
                      .length ??
                  0),
        ) /
        recordedMatches.length;
  }

  //TODO the match results process returns a record with a value and optional string error.
  //this might not be the best way to implement it, as the behavior/typing is slightly ambiguous
  //
  ({double? value, String? error})? runMatchResultsProcess(
    MatchResultsProcess process,
    RobotMatchTraceData? matchResults,
    DynamicProperties? matchSurvey,
    int team,
  ) {
    if (matchResults == null) {
      return null;
    }

    final exp = Expression(process.expression);

    //Returns 1 if the team's pit scouting data matches 0 otherwise.
    exp.addLazyFunction(
      LazyFunctionImpl(
        "PITSCOUTINGIS",
        2,
        fEval: (params) {
          if (pitscouting[team.toString()]?[params[0].getString()].toString() ==
              params[1].getString()) {
            return LazyNumberImpl(
              eval: () => Decimal.fromInt(1),
              getString: () => "1",
            );
          } else {
            return LazyNumberImpl(
              eval: () => Decimal.fromInt(0),
              getString: () => "0",
            );
          }
        },
      ),
    );

    //Returns 1 if a post game survey item matches the value 0 otherwise
    exp.addLazyFunction(
      LazyFunctionImpl(
        "POSTGAMEIS",
        2,
        fEval: (params) {
          if (matchSurvey?[params[0].getString()].toString() ==
              params[1].getString()) {
            return LazyNumberImpl(
              eval: () => Decimal.fromInt(1),
              getString: () => "1",
            );
          } else {
            return LazyNumberImpl(
              eval: () => Decimal.fromInt(0),
              getString: () => "0",
            );
          }
        },
      ),
    );

    // Returns number of events with a specific name within a bbox
    //   -- O
    // |    |
    // |    |
    // o --
    // min x, min y, max X, max Y
    exp.addLazyFunction(
      LazyFunctionImpl(
        "EVENTINBBOX",
        5,
        fEval: (params) {
          final int value = matchResults.timelineInterpolated
              .where(
                (element) =>
                    element.id == params[0].getString() &&
                    element.position.x >= params[1].eval()!.toDouble() &&
                    element.position.y >= params[2].eval()!.toDouble() &&
                    element.position.x <= params[3].eval()!.toDouble() &&
                    element.position.y <= params[4].eval()!.toDouble(),
              )
              .length;
          return LazyNumberImpl(
            eval: () => Decimal.fromInt(value),
            getString: () => value.toString(),
          );
        },
      ),
    );

    // Returns number of events with a specific name within a bbox
    //   -- O
    // |    |
    // |    |
    // o --
    // min x, min y, max X, max Y
    exp.addLazyFunction(
      LazyFunctionImpl(
        "AUTOEVENTINBBOX",
        5,
        fEval: (params) {
          final int value = matchResults.timelineInterpolated
              .where(
                (element) =>
                    element.isInAuto &&
                    element.id == params[0].getString() &&
                    element.position.x >= params[1].eval()!.toDouble() &&
                    element.position.y >= params[2].eval()!.toDouble() &&
                    element.position.x <= params[3].eval()!.toDouble() &&
                    element.position.y <= params[4].eval()!.toDouble(),
              )
              .length;
          return LazyNumberImpl(
            eval: () => Decimal.fromInt(value),
            getString: () => value.toString(),
          );
        },
      ),
    );

    // Returns number of events with a specific name within a bbox
    //   -- O
    // |    |
    // |    |
    // o --
    // min x, min y, max X, max Y
    exp.addLazyFunction(
      LazyFunctionImpl(
        "TELEOPEVENTINBBOX",
        5,
        fEval: (params) {
          final int value = matchResults.timelineInterpolated
              .where(
                (element) =>
                    element.isInAuto == false &&
                    element.id == params[0].getString() &&
                    element.position.x >= params[1].eval()!.toDouble() &&
                    element.position.y >= params[2].eval()!.toDouble() &&
                    element.position.x <= params[3].eval()!.toDouble() &&
                    element.position.y <= params[4].eval()!.toDouble(),
              )
              .length;
          return LazyNumberImpl(
            eval: () => Decimal.fromInt(value),
            getString: () => value.toString(),
          );
        },
      ),
    );

    //adder that counts the number of a specific event in the timeline
    exp.addLazyFunction(
      LazyFunctionImpl(
        "EVENT",
        1,
        fEval: (params) {
          final int value = matchResults.timeline
              .where((element) => element.id == params[0].getString())
              .length;
          return LazyNumberImpl(
            eval: () => Decimal.fromInt(value),
            getString: () => value.toString(),
          );
        },
      ),
    );

    //adder that counts the number of a specific event in the timeline
    exp.addLazyFunction(
      LazyFunctionImpl(
        "AUTOEVENT",
        1,
        fEval: (params) {
          final int value = matchResults.timeline
              .where(
                (element) =>
                    element.isInAuto && element.id == params[0].getString(),
              )
              .length;
          return LazyNumberImpl(
            eval: () => Decimal.fromInt(value),
            getString: () => value.toString(),
          );
        },
      ),
    );

    //adder that counts the number of a specific event in the timeline
    exp.addLazyFunction(
      LazyFunctionImpl(
        "TELEOPEVENT",
        1,
        fEval: (params) {
          final int value = matchResults.timeline
              .where(
                (element) =>
                    element.isInAuto == false &&
                    element.id == params[0].getString(),
              )
              .length;
          return LazyNumberImpl(
            eval: () => Decimal.fromInt(value),
            getString: () => value.toString(),
          );
        },
      ),
    );

    //returns the result of another process for this data.
    exp.addLazyFunction(
      LazyFunctionImpl(
        "PROCESS",
        1,
        fEval: (params) {
          final String processID = params[0].getString();
          if (process.id == processID) {
            throw Exception("cannot recursively call a process");
          }
          final MatchResultsProcess? otherProcess = config
              .matchscouting
              .processes
              .firstWhereOrNull((element) => element.id == processID);
          if (otherProcess == null) {
            throw Exception("process $processID does not exist");
          }
          final result = runMatchResultsProcess(
            otherProcess,
            matchResults,
            matchSurvey,
            team,
          );
          return LazyNumberImpl(
            eval: () => Decimal.parse(result!.value.toString()),
            getString: () => result!.value.toString(),
          );
        },
      ),
    );

    try {
      return (value: exp.eval()?.toDouble(), error: null);
    } catch (e) {
      return (value: null, error: '$e ${process.expression}');
    }
  }

  /// Returns the average value of a given metric per match over all recorded matches.
  /// returns null if there is no data. Otherwise we get weird NaN stuff and
  /// if you add NaN to anything it completely destroys the whole calculation
  /// There is an optional where clause to filter the events out for a specific type
  double? teamAverageProcess(int team, MatchResultsProcess process) {
    final recordedMatches = teamRecordedMatches(team);

    if (recordedMatches.isEmpty) {
      return null;
    }

    return recordedMatches.fold<double>(
          0,
          (previousValue, match) =>
              previousValue +
              (runMatchResultsProcess(
                    process,
                    match.value.robot[team.toString()],
                    matchSurvey(team, match.key) ?? DynamicProperties(),
                    team,
                  )?.value ??
                  0),
        ) /
        recordedMatches.length;
  }
}
