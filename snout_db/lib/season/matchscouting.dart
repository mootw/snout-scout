import 'package:json_annotation/json_annotation.dart';
import 'package:snout_db/season/matchevent.dart';
import 'package:snout_db/season/surveyitem.dart';

part 'matchscouting.g.dart';

@JsonSerializable()
class MatchScouting {
  List<MatchEvent> auto;
  List<MatchEvent> teleop;
  List<SurveyItem> postgame;
  List<String> scoring;

  MatchScouting(
      {required this.auto,
      required this.teleop,
      required this.postgame,
      required this.scoring});

  factory MatchScouting.fromJson(Map<String, dynamic> json) =>
      _$MatchScoutingFromJson(json);
  Map<String, dynamic> toJson() => _$MatchScoutingToJson(this);
}
