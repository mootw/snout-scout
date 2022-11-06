import 'package:json_annotation/json_annotation.dart';
import 'package:snout_db/event/matchresults.dart';
import 'package:snout_db/season/matchevent.dart';

part 'match.g.dart';

@JsonSerializable()
class FRCMatch {
  
  get id => "$level$number";
  int number; //match number hould be unique per level
  TournamentLevel? level;
  String description;
  DateTime scheduledTime;
  List<int> blue;
  List<int> red;
  MatchResults? results;
  Map<String, List<MatchEvent>> timelines;

  FRCMatch({required this.level, required this.description,
  required this.number, required this.scheduledTime, required this.blue,
  required this.red, required this.results, required this.timelines});

  factory FRCMatch.fromJson(Map<String, dynamic> json) => _$FRCMatchFromJson(json);
  Map<String, dynamic> toJson() => _$FRCMatchToJson(this);

  //Helpers
  get hasTeam => (int team) => red.contains(team) || blue.contains(team);
}


enum TournamentLevel { None, Practice, Qualification, Playoff }