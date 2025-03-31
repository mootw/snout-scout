import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:snout_db/event/dynamic_property.dart';
import 'package:snout_db/event/frcevent.dart';
import 'package:snout_db/event/match_schedule_item.dart';
import 'package:snout_db/event/matchresults.dart';
import 'package:snout_db/event/robotmatchresults.dart';

part 'match_data.g.dart';

@immutable
@JsonSerializable()
class MatchData {
  ///results of the match (null if the match has not been played)
  final MatchResultValues? results;

  /// values stored on a per match basis. like pit scouting for a match
  final DynamicProperties? properties;

  /// Performance of each robot during the match
  /// this map might include surrogate robots (aka robots that are not in the union of the scheduled teams)
  final Map<String, RobotMatchResults> robot;

  const MatchData({
    required this.results,
    // For backwards compatibility
    this.properties = const {},
    this.robot = const {},
  });

  MatchScheduleItem? getSchedule(FRCEvent event, String id) =>
      event.schedule[id];

  factory MatchData.fromJson(Map json) => _$MatchDataFromJson(json);
  Map toJson() => _$MatchDataToJson(this);
}
