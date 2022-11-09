import 'package:json_annotation/json_annotation.dart';
import 'package:snout_db/event/matchresults.dart';
import 'package:snout_db/event/robotmatchresults.dart';
import 'package:snout_db/season/matchevent.dart';

part 'match.g.dart';

@JsonSerializable()
class FRCMatch {
  
  get id => "$level$number";
  ///The number of this match in the series
  int number;
  //The level that this match is at
  TournamentLevel? level;
  ///desciption aka the match name (Qualitication 1, Quarters 3 Match 1, Semifinals 2)
  String description;
  ///time the match was scheduled for, and is how matches should be sorted.
  DateTime scheduledTime;
  ///list of blue teams
  List<int> blue;
  /// list of red teams
  List<int> red;
  ///results of the match (null if the match has not been played)
  MatchResults? results;

  /// Performance of each robot during the match
  Map<String, RobotMatchResults> robot;

  FRCMatch({required this.level, required this.description,
  required this.number, required this.scheduledTime, required this.blue,
  required this.red, required this.results, required this.robot});

  factory FRCMatch.fromJson(Map<String, dynamic> json) => _$FRCMatchFromJson(json);
  Map<String, dynamic> toJson() => _$FRCMatchToJson(this);

  //Helpers
  bool hasTeam (int team) => red.contains(team) || blue.contains(team);

  String getTeamColor (int team) => red.contains(team) ? "red" : "blue";

  Duration? get scheduleDelay => results?.time.difference(scheduledTime);
}


enum TournamentLevel { None, Practice, Qualification, Playoff }