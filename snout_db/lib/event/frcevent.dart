import 'dart:collection';

import 'package:json_annotation/json_annotation.dart';
import 'package:snout_db/event/matchevent.dart';
import 'package:snout_db/event/pitscoutresult.dart';
import 'match.dart';
import 'package:collection/collection.dart';
import 'package:snout_db/config/eventconfig.dart';

part 'frcevent.g.dart';

@JsonSerializable()
class FRCEvent {
  ///List of teams in the event, ideally ordered smallest number to largest
  final List<int> teams;

  /// how should this event be tracked?
  final EventConfig config;

  ///List of matches
  final SplayTreeMap<String, FRCMatch> matches;

  //Pit scouting results
  final Map<String, PitScoutResult> pitscouting;

  //Enforce that all matches are sorted
  FRCEvent(
      {required this.config,
      required this.teams,
      required Map<String, FRCMatch> matches,
      required this.pitscouting})
      //Enforce that the matches are sorted correctly
      : matches = SplayTreeMap.from(matches,
            (key1, key2) => Comparable.compare(matches[key1]!, matches[key2]!));

  factory FRCEvent.fromJson(Map<String, dynamic> json) =>
      _$FRCEventFromJson(json);
  Map<String, dynamic> toJson() => _$FRCEventToJson(this);

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
      .lastWhereOrNull((match) => match.results == null);

  FRCMatch? nextMatchForTeam(int team) => matchesWithTeam(team)
      .reversed
      .lastWhereOrNull((match) => match.results == null);

  //Calculates the schedule delay by using the delay of the last match with results actual time versus the scheduled time.
  Duration? get scheduleDelay => matches.values
      .lastWhereOrNull((match) => match.results != null)
      ?.scheduleDelay;

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
}
