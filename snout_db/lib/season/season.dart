import 'package:json_annotation/json_annotation.dart';
import 'package:snout_db/season/matchscouting.dart';
import 'package:snout_db/season/pitsurveyitem.dart';

part 'season.g.dart';

@JsonSerializable()
class Season {


  String season;
  int team;
  List<PitSurveyItem> pitscouting;
  MatchScouting matchscouting;

  Season({required this.team, required this.season, required this.pitscouting, required this.matchscouting});

  factory Season.fromJson(Map<String, dynamic> json) => _$SeasonFromJson(json);
  Map<String, dynamic> toJson() => _$SeasonToJson(this);
}