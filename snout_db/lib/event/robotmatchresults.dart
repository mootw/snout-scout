import 'package:json_annotation/json_annotation.dart';
import 'package:snout_db/event/pitscoutresult.dart';
import 'package:snout_db/season/matchevent.dart';

part 'robotmatchresults.g.dart';

@JsonSerializable()
class RobotMatchResults {
  
  /// List of events this robot did during the match
  List<MatchEvent> timeline;
  //Post game survey like pit scouting; but used for scoring too
  List<PitScoutResult> survey;

  RobotMatchResults({required this.timeline, required this.survey});

  factory RobotMatchResults.fromJson(Map<String, dynamic> json) => _$RobotMatchResultFromJson(json);
  Map<String, dynamic> toJson() => _$RobotMatchResultToJson(this);
}
