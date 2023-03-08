import 'package:json_annotation/json_annotation.dart';
import 'package:snout_db/config/matchscouting.dart';
import 'package:snout_db/config/surveyitem.dart';

part 'eventconfig.g.dart';

@JsonSerializable()
class EventConfig {
  ///Human readable name for this event (the one displayed on the status bar)
  final String name;
  //year for this season; used to determine which field to display
  final int season;
  //Event ID on TBA used to link rankings and other data (Optional)
  final String? tbaEventId;
  //Determines how the app will normalize event positions
  final FieldStyle fieldStyle;
  //Your team number
  final int team;
  final List<SurveyItem> pitscouting;
  final MatchScouting matchscouting;

  EventConfig(
      {required this.name,
      required this.team,
      required this.season,
      required this.tbaEventId,
      required this.fieldStyle,
      required this.pitscouting,
      required this.matchscouting});

  factory EventConfig.fromJson(Map<String, dynamic> json) =>
      _$EventConfigFromJson(json);
  Map<String, dynamic> toJson() => _$EventConfigToJson(this);
}

enum FieldStyle { rotated, mirrored }
