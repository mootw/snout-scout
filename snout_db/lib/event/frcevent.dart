import 'dart:collection';

import 'package:decimal/decimal.dart';
import 'package:eval_ex/built_ins.dart';
import 'package:eval_ex/expression.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:rfc_6901/rfc_6901.dart';
import 'package:snout_db/config/matchresults_process.dart';
import 'package:snout_db/event/matchevent.dart';
import 'package:snout_db/event/pitscoutresult.dart';
import 'package:snout_db/event/robotmatchresults.dart';
import 'package:snout_db/patch.dart';
import 'match.dart';
import 'package:collection/collection.dart';
import 'package:snout_db/config/eventconfig.dart';

part 'frcevent.g.dart';

@JsonSerializable()
class FRCEvent {
  /// how should this event be tracked?
  final EventConfig config;

  ///List of teams in the event, ideally ordered smallest number to largest
  final List<int> teams;

  ///List of matches
  final SplayTreeMap<String, FRCMatch> matches;

  //Pit scouting results
  final Map<String, PitScoutResult> pitscouting;

  /// image of the pit map
  final String? pitmap;

  //Enforce that all matches are sorted
  FRCEvent(
      {required this.config,
      this.teams = const [],
      Map<String, FRCMatch> matches = const {},
      this.pitscouting = const {},
      this.pitmap})
      //Enforce that the matches are sorted correctly
      : matches = SplayTreeMap.from(matches,
            (key1, key2) => Comparable.compare(matches[key1]!, matches[key2]!));

  factory FRCEvent.fromJson(Map json) => _$FRCEventFromJson(json);
  Map toJson() => _$FRCEventToJson(this);

  /// "performant" way to load a database state from a list patches
  /// note, this will fail if the resulting structure does not match
  /// a valid FRCEvent
  static FRCEvent fromPatches(List<Patch> patches) {
    //Start with empty!
    var dbJson;
    for (final patch in patches) {
      if (dbJson == null) {
        //Initialize the db with the first patch's data.
        dbJson = FRCEvent.fromJson(patch.value as Map).toJson();
        continue;
      }
      dbJson = JsonPointer(patch.path).write(dbJson, patch.value);
    }
    return FRCEvent.fromJson(dbJson);
  }

  //Returns the id for a given match
  String matchIDFromMatch(FRCMatch match) =>
      matches.keys.toList()[matches.values.toList().indexOf(match)];

  /// returns matches with a specific team in them
  List<FRCMatch> matchesWithTeam(int team) =>
      matches.values.where((match) => match.hasTeam(team)).toList();

  //returns the match after the last match with results
  FRCMatch? get nextMatch => matches.values
      .toList()
      .reversed
      .lastWhereOrNull((match) => match.isComplete == false);

  FRCMatch? nextMatchForTeam(int team) => matchesWithTeam(team)
      .reversed
      .lastWhereOrNull((match) => match.isComplete == false);

  //Calculates the schedule delay by using the delay of the last match with results actual time versus the scheduled time.
  Duration? get scheduleDelay => matches.values
      .lastWhereOrNull((match) => match.isComplete)
      ?.delayFromScheduledTime;

  /// Returns all matches that include a recording for a specific team
  Iterable<MapEntry<String, FRCMatch>> teamRecordedMatches(int team) => matches
      .entries
      .where((element) => element.value.robot.keys.contains(team.toString()));

  /// Returns the average value of a given metric per match over all recorded matches.
  /// returns null if there is no data. Otherwise we get weird NaN stuff and
  /// if you add NaN to anything it completely destroys the whole calculation
  /// There is an optional where clause to filter the events out for a specific type
  double? teamAverageMetric(int team, String eventId,
      [Function(MatchEvent)? where]) {
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
                        .where((event) =>
                            event.id == eventId && (where?.call(event) ?? true))
                        .length ??
                    0)) /
        recordedMatches.length;
  }

  /// For each recorded match of this team, it will return a map of each
  /// Value with the key being the value, and the value being the percent frequency
  /// The map will be empty if there are no recordings
  Map<String, double> teamPostGameSurveyByFrequency(int team, String eventId) {
    final recordedMatches = teamRecordedMatches(team);
    Map<String, double> toReturn = {};

    for (final match in recordedMatches) {
      final surveyValue =
          match.value.robot[team.toString()]!.survey[eventId]?.toString();
      if (surveyValue == null) {
        continue;
      }
      if (toReturn[surveyValue] == null) {
        toReturn[surveyValue] = 1;
      } else {
        toReturn[surveyValue] = toReturn[surveyValue]! + 1;
      }
    }
    //We have to calculate the total values since not all matches have a survey value
    final totalValues = toReturn.values
        .fold<double>(0, (previousValue, element) => previousValue + element);
    //Convert the map to be a percentage rather than total sum
    toReturn = toReturn.map((key, value) => MapEntry(key, value / totalValues));
    return toReturn;
  }

  //TODO the match results process returns a record with a value and optional string error.
  //this might not be the best way to implement it, as the behavior/typing is slightly ambiguous
  //
  ({double? value, String? error})? runMatchResultsProcess(
      MatchResultsProcess process, RobotMatchResults? matchResults, int team) {
    if (matchResults == null) {
      return null;
    }

    final exp = Expression(process.expression);

    //Returns 1 if the team's pit scouting data matches 0 otherwise.
    exp.addLazyFunction(LazyFunctionImpl("PITSCOUTINGIS", 2, fEval: (params) {
      if (pitscouting[team.toString()]?[params[0].getString()].toString() ==
          params[1].getString()) {
        return LazyNumberImpl(
            eval: () => Decimal.fromInt(1), getString: () => "1");
      } else {
        return LazyNumberImpl(
            eval: () => Decimal.fromInt(0), getString: () => "0");
      }
    }));

    //Returns 1 if a post game survey item matches the value 0 otherwise
    exp.addLazyFunction(LazyFunctionImpl("POSTGAMEIS", 2, fEval: (params) {
      if (matchResults.survey[params[0].getString()].toString() ==
          params[1].getString()) {
        return LazyNumberImpl(
            eval: () => Decimal.fromInt(1), getString: () => "1");
      } else {
        return LazyNumberImpl(
            eval: () => Decimal.fromInt(0), getString: () => "0");
      }
    }));

    // Returns number of events with a specific name within a bbox
    //   -- O
    // |    |
    // |    |
    // o --
    // min x, min y, max X, max Y
    exp.addLazyFunction(LazyFunctionImpl("EVENTINBBOX", 5, fEval: (params) {
      int value = matchResults.timelineInterpolated
          .where((element) =>
              element.id == params[0].getString() &&
              element.position.x >= params[1].eval()!.toDouble() &&
              element.position.y >= params[2].eval()!.toDouble() &&
              element.position.x <= params[3].eval()!.toDouble() &&
              element.position.y <= params[4].eval()!.toDouble())
          .length;
      return LazyNumberImpl(
          eval: () => Decimal.fromInt(value),
          getString: () => value.toString());
    }));

    // Returns number of events with a specific name within a bbox
    //   -- O
    // |    |
    // |    |
    // o --
    // min x, min y, max X, max Y
    exp.addLazyFunction(LazyFunctionImpl("AUTOEVENTINBBOX", 5, fEval: (params) {
      int value = matchResults.timelineInterpolated
          .where((element) =>
              element.isInAuto &&
              element.id == params[0].getString() &&
              element.position.x >= params[1].eval()!.toDouble() &&
              element.position.y >= params[2].eval()!.toDouble() &&
              element.position.x <= params[3].eval()!.toDouble() &&
              element.position.y <= params[4].eval()!.toDouble())
          .length;
      return LazyNumberImpl(
          eval: () => Decimal.fromInt(value),
          getString: () => value.toString());
    }));

    // Returns number of events with a specific name within a bbox
    //   -- O
    // |    |
    // |    |
    // o --
    // min x, min y, max X, max Y
    exp.addLazyFunction(
        LazyFunctionImpl("TELEOPEVENTINBBOX", 5, fEval: (params) {
      int value = matchResults.timelineInterpolated
          .where((element) =>
              element.isInAuto == false &&
              element.id == params[0].getString() &&
              element.position.x >= params[1].eval()!.toDouble() &&
              element.position.y >= params[2].eval()!.toDouble() &&
              element.position.x <= params[3].eval()!.toDouble() &&
              element.position.y <= params[4].eval()!.toDouble())
          .length;
      return LazyNumberImpl(
          eval: () => Decimal.fromInt(value),
          getString: () => value.toString());
    }));

    //adder that counts the number of a specific event in the timeline
    exp.addLazyFunction(LazyFunctionImpl("EVENT", 1, fEval: (params) {
      int value = matchResults.timeline
          .where((element) => element.id == params[0].getString())
          .length;
      return LazyNumberImpl(
          eval: () => Decimal.fromInt(value),
          getString: () => value.toString());
    }));

    //adder that counts the number of a specific event in the timeline
    exp.addLazyFunction(LazyFunctionImpl("AUTOEVENT", 1, fEval: (params) {
      int value = matchResults.timeline
          .where((element) =>
              element.isInAuto && element.id == params[0].getString())
          .length;
      return LazyNumberImpl(
          eval: () => Decimal.fromInt(value),
          getString: () => value.toString());
    }));

    //adder that counts the number of a specific event in the timeline
    exp.addLazyFunction(LazyFunctionImpl("TELEOPEVENT", 1, fEval: (params) {
      int value = matchResults.timeline
          .where((element) =>
              element.isInAuto == false && element.id == params[0].getString())
          .length;
      return LazyNumberImpl(
          eval: () => Decimal.fromInt(value),
          getString: () => value.toString());
    }));

    //returns the result of another process for this data.
    exp.addLazyFunction(LazyFunctionImpl("PROCESS", 1, fEval: (params) {
      String processID = params[0].getString();
      if (process.id == processID) {
        throw Exception("cannot recursively call a process");
      }
      MatchResultsProcess? otherProcess = config.matchscouting.processes
          .firstWhereOrNull((element) => element.id == processID);
      if (otherProcess == null) {
        throw Exception("process ${processID} does not exist");
      }
      final result = runMatchResultsProcess(otherProcess, matchResults, team);
      return LazyNumberImpl(
          eval: () => Decimal.parse(result!.value.toString()),
          getString: () => result!.value.toString());
    }));

    try {
      return (value: exp.eval()?.toDouble(), error: null);
    } catch (e) {
      return (value: null, error: '${e.toString()} ${process.expression}');
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
                            process, match.value.robot[team.toString()], team)
                        ?.value ??
                    0)) /
        recordedMatches.length;
  }
}
