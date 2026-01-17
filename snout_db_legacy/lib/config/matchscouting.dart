import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:snout_db_legacy/config/matcheventconfig.dart';
import 'package:snout_db_legacy/config/matchresults_process.dart';
import 'package:snout_db_legacy/config/surveyitem.dart';

part 'matchscouting.g.dart';

@JsonSerializable()
@immutable
class MatchScouting {
  /// Buttons that show to scouts to record specific events
  final List<MatchEventConfig> events;

  /// Defines how the match datas are calculated and displayed.
  final List<MatchResultsProcess> processes;

  /// survey that is displayed at the end of the game related
  /// to the team that the scout was watching.
  final List<SurveyItem> survey;

  /// properties stored on a per match basis
  final List<SurveyItem> properties;

  const MatchScouting({
    this.events = const [],
    this.processes = const [],
    this.survey = const [],
    this.properties = const [],
  });

  factory MatchScouting.fromJson(Map<String, dynamic> json) =>
      _$MatchScoutingFromJson(json);
  Map<String, dynamic> toJson() => _$MatchScoutingToJson(this);
}
