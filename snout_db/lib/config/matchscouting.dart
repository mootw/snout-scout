import 'package:json_annotation/json_annotation.dart';
import 'package:snout_db/config/matchevent_process.dart';
import 'package:snout_db/config/matcheventconfig.dart';
import 'package:snout_db/config/surveyitem.dart';

part 'matchscouting.g.dart';

@JsonSerializable()
class MatchScouting {
  
  //Buttons that show to scouts to record specific events
  final List<MatchEventConfig> events;
  //Defines how the events are calculated and displayed.
  final List<MatchEventProcess> eventProcess;
  //survey that is displayed at the end of the game related
  //to the team that the scout was watching. 
  final List<SurveyItem> postgame;
  //generally just 'points' and 'rp'
  final List<String> scoring;

  const MatchScouting(
      {this.events = const [],
      this.eventProcess = const [],
      this.postgame = const [],
      this.scoring = const ['points', 'rp']});

  factory MatchScouting.fromJson(Map<String, dynamic> json) =>
      _$MatchScoutingFromJson(json);
  Map<String, dynamic> toJson() => _$MatchScoutingToJson(this);

}
