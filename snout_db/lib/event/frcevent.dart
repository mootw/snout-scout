import 'dart:collection';

import 'package:json_annotation/json_annotation.dart';
import 'package:snout_db/event/pitscoutresult.dart';
import 'match.dart';
import 'package:collection/collection.dart';
import 'package:snout_db/config/eventconfig.dart';

part 'frcevent.g.dart';

@JsonSerializable()
class FRCEvent {

  ///List of teams in the event, ideally ordered smallest number to largest
  List<int> teams;

  /// how should this event be tracked?
  EventConfig config;

  ///List of matches
  SplayTreeMap<String, FRCMatch> matches;

  //Pit scouting results
  Map<String, PitScoutResult> pitscouting;

  //Enforce that all matches are sorted
  FRCEvent(
      {required this.config,
      required this.teams,
      required Map<String, FRCMatch> matches,
      required this.pitscouting})
      //Enforce that the matches are sorted in ascending time.
      : matches = SplayTreeMap.from(
            matches,
            (key1, key2) => matches[key1]!
                .scheduledTime
                .difference(matches[key2]!.scheduledTime)
                .inMilliseconds);

  factory FRCEvent.fromJson(Map<String, dynamic> json) =>
      _$FRCEventFromJson(json);
  Map<String, dynamic> toJson() => _$FRCEventToJson(this);

  //Returns the id for a given match
  String matchIDFromMatch (FRCMatch match) => matches.keys.toList()[matches.values.toList().indexOf(match)];

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
}
