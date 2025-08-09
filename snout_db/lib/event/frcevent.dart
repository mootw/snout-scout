import 'package:collection/collection.dart';
import 'package:decimal/decimal.dart';
import 'package:eval_ex/built_ins.dart';
import 'package:eval_ex/expression.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:rfc_6901/rfc_6901.dart';
import 'package:snout_db/config/eventconfig.dart';
import 'package:snout_db/config/matchresults_process.dart';
import 'package:snout_db/event/dynamic_property.dart';
import 'package:snout_db/event/match_data.dart';
import 'package:snout_db/event/match_schedule_item.dart';
import 'package:snout_db/event/matchevent.dart';
import 'package:snout_db/event/robotmatchresults.dart';
import 'package:snout_db/patch.dart';

part 'frcevent.g.dart';

const scheduleBreakDuration = Duration(minutes: 29);

@immutable
@JsonSerializable()
class FRCEvent {
  /// how should this event be tracked?
  final EventConfig config;

  ///List of teams in the event, ideally ordered smallest number to largest
  final List<int> teams;

  // Match schedule configuration. This is a Map Type to avoid insertion collisions.
  // Technically a list type is more ideal, and it is expensive to remove an item
  // but that is rarely required
  final Map<String, MatchScheduleItem> schedule;

  // Sorted schedule. Important for some lookups
  List<MatchScheduleItem> get scheduleSorted => schedule.values.sorted();

  /// Match Data
  final Map<String, MatchData> matches;

  List<MapEntry<String, MatchData>> matchesSorted() {
    return matches.entries.sorted((a, b) {
      final aValue = a.value.getSchedule(this, a.key);
      final bValue = b.value.getSchedule(this, b.key);

      return aValue == null || bValue == null ? 0 : aValue.compareTo(bValue);
    });
  }

  //Team Survey results
  final Map<String, DynamicProperties> pitscouting;

  /// image of the pit map
  final String? pitmap;

  // List of registered scouts and their passwords
  final Map<String, String> scoutPasswords;

  //Enforce that all matches are sorted
  const FRCEvent({
    required this.config,
    this.teams = const [],
    this.schedule = const {},
    this.matches = const {},
    this.pitscouting = const {},
    this.scoutPasswords = const {},
    this.pitmap,
  });

  factory FRCEvent.fromJson(Map json) => _$FRCEventFromJson(json);
  Map toJson() => _$FRCEventToJson(this);

  /// "performant" way to load a database state from a list patches
  /// note, this will fail if the resulting structure does not match
  /// a valid FRCEvent
  factory FRCEvent.fromPatches(List<Patch> patches) {
    //Start with empty!
    Map? dbJson;
    for (final patch in patches) {
      if (dbJson == null) {
        //Initialize the db with the first patch's data.
        dbJson = FRCEvent.fromJson(patch.value! as Map).toJson();
        continue;
      }
      dbJson = JsonPointer(patch.path).write(dbJson, patch.value)! as Map;
    }
    return FRCEvent.fromJson(dbJson!);
  }

  /// returns matches SCHEDULED to have a specific team in them.
  /// this is NOT the same as teamRecordedMatches which is all matches
  /// that are actually recorded
  List<MatchScheduleItem> matchesWithTeam(int team) =>
      scheduleSorted
          .where((match) => match.isScheduledToHaveTeam(team))
          .toList();

  //returns the match after the last match with results
  MatchScheduleItem? get nextMatch => scheduleSorted
      .toList()
      .reversed
      .lastWhereOrNull((match) => match.isComplete(this) == false);

  MatchScheduleItem? nextMatchForTeam(int team) => matchesWithTeam(
    team,
  ).reversed.lastWhereOrNull((match) => match.isComplete(this) == false);

  //Calculates the schedule delay by using the delay of the last match with results actual time versus the scheduled time.
  Duration? get scheduleDelay {
    final nextMatch = scheduleSorted.lastWhereOrNull(
      (match) => match.isComplete(this),
    );

    final matchAfterNext =
        nextMatch == null
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
    RobotMatchResults? matchResults,
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
          if (matchResults.survey[params[0].getString()].toString() ==
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
          final int value =
              matchResults.timelineInterpolated
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
          final int value =
              matchResults.timelineInterpolated
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
          final int value =
              matchResults.timelineInterpolated
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
          final int value =
              matchResults.timeline
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
          final int value =
              matchResults.timeline
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
          final int value =
              matchResults.timeline
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
                    team,
                  )?.value ??
                  0),
        ) /
        recordedMatches.length;
  }
}
