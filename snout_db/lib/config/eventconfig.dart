import 'package:json_annotation/json_annotation.dart';
import 'package:snout_db/config/matchscouting.dart';
import 'package:snout_db/config/surveyitem.dart';

part 'eventconfig.g.dart';

@JsonSerializable()
class EventConfig {

  //name for the season. Doesn't particularly matter
  String season;
  int team;
  List<SurveyItem> pitscouting;
  MatchScouting matchscouting;

  EventConfig({required this.team, required this.season, required this.pitscouting, required this.matchscouting});

  factory EventConfig.fromJson(Map<String, dynamic> json) => _$EventConfigFromJson(json);
  Map<String, dynamic> toJson() => _$EventConfigToJson(this);
}