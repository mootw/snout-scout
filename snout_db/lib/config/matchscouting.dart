import 'package:json_annotation/json_annotation.dart';
import 'package:snout_db/config/matcheventconfig.dart';
import 'package:snout_db/config/surveyitem.dart';

part 'matchscouting.g.dart';

@JsonSerializable()
class MatchScouting {
  
  List<MatchEventConfig> events;
  Map<String, dynamic> eventValues;
  List<SurveyItem> postgame;
  List<String> scoring;

  MatchScouting(
      {required this.events,
      required this.eventValues,
      required this.postgame,
      required this.scoring});

  factory MatchScouting.fromJson(Map<String, dynamic> json) =>
      _$MatchScoutingFromJson(json);
  Map<String, dynamic> toJson() => _$MatchScoutingToJson(this);

}
