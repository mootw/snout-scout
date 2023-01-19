import 'package:json_annotation/json_annotation.dart';
import 'package:snout_db/config/matchscouting.dart';
import 'package:snout_db/config/surveyitem.dart';

part 'eventconfig.g.dart';

@JsonSerializable()
class EventConfig {

  //name for the season. Doesn't particularly matter
  String season;
  //Determines how the app will normalize event positions
  FieldStyle fieldStyle;
  //Your team number
  int team;
  List<SurveyItem> pitscouting;
  MatchScouting matchscouting;

  EventConfig(
      {required this.team,
      required this.season,
      required this.fieldStyle,
      required this.pitscouting,
      required this.matchscouting});

  factory EventConfig.fromJson(Map<String, dynamic> json) =>
      _$EventConfigFromJson(json);
  Map<String, dynamic> toJson() => _$EventConfigToJson(this);
}

enum FieldStyle { rotated, mirrored }
