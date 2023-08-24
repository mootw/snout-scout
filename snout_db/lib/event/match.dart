import 'package:json_annotation/json_annotation.dart';
import 'package:snout_db/event/matchresults.dart';
import 'package:snout_db/event/robotmatchresults.dart';
import 'package:snout_db/game.dart';

part 'match.g.dart';

@JsonSerializable()
class FRCMatch implements Comparable<FRCMatch> {

  ///aka the match name (Qualitication 1, Quarters 3 Match 1, Semifinals 2)
  final String description;

  ///time the match was scheduled for
  final DateTime scheduledTime;

  /// list of scheduled red teams
  final List<int> red;

  ///list of scheduled blue teams
  final List<int> blue;

  ///results of the match (null if the match has not been played)
  final MatchResultValues? results;

  /// Performance of each robot during the match
  /// this map might include surrogate robots (aka robots that are not in the union of the scheduled teams)
  final Map<String, RobotMatchResults> robot;

  FRCMatch(
      {
      required this.description,
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
  int compareTo(other) => scheduledTime.difference(other.scheduledTime).inMicroseconds;


  bool hasTeam(int team) => red.contains(team) || blue.contains(team);

  Alliance getAllianceOf(int team) => red.contains(team) ? Alliance.red : Alliance.blue;
  
  /// difference between the time that the match was scheduled and the actual time
  /// the match started
  Duration? get delayFromScheduledTime => results?.time.difference(scheduledTime);

  /// returns if we have 'any' data for the match to help with
  /// if match results are not submitted but a recording was to calculate
  /// scheduling delays
  bool get isComplete => results != null || robot.entries.isNotEmpty;
}
