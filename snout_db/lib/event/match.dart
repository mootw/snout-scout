import 'package:json_annotation/json_annotation.dart';
import 'package:snout_db/event/matchresults.dart';
import 'package:snout_db/event/robotmatchresults.dart';
import 'package:snout_db/game.dart';

part 'match.g.dart';

@JsonSerializable()
class FRCMatch extends Comparable<FRCMatch> {
  ///The number of this match in the series
  final int number;

  ///desciption aka the match name (Qualitication 1, Quarters 3 Match 1, Semifinals 2)
  final String description;

  ///time the match was scheduled for, and is how matches should be sorted.
  final DateTime scheduledTime;

  /// list of red teams
  final List<int> red;

  ///list of blue teams
  final List<int> blue;

  ///results of the match (null if the match has not been played)
  final MatchResults? results;

  /// Performance of each robot during the match
  final Map<String, RobotMatchResults> robot;

  FRCMatch(
      {
      required this.description,
      required this.number,
      required this.scheduledTime,
      required this.red,
      required this.blue,
      required this.results,
      required this.robot});

  factory FRCMatch.fromJson(Map<String, dynamic> json) =>
      _$FRCMatchFromJson(json);
  Map<String, dynamic> toJson() => _$FRCMatchToJson(this);

  //Default sorting should be based on match time
  @override
  int compareTo(other) => scheduledTime.difference(other.scheduledTime).inMilliseconds;

  //Helpers
  bool hasTeam(int team) => red.contains(team) || blue.contains(team);

  // Returns the alliance the team is on, otherwise null if the team is not part of the schedule.
  Alliance getAllianceOf(int team) => red.contains(team) ? Alliance.red : Alliance.blue;
  
  Duration? get scheduleDelay => results?.time.difference(scheduledTime);
}
