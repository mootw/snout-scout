import 'package:json_annotation/json_annotation.dart';
import 'package:snout_db/event/frcevent.dart';
import 'package:snout_db/event/match_schedule_item.dart';
import 'package:snout_db/event/robot_match_trace.dart';

part 'match_data.g.dart';

@JsonSerializable()
class MatchData {

  /// Performance of each robot during the match
  /// this map might include surrogate robots (aka robots that are not in the union of the scheduled teams)
  Map<String, RobotMatchTraceData> robot = {};

  MatchData({
    // For backwards compatibility
    required this.robot,
  });

  MatchScheduleItem? getSchedule(FRCEvent event, String id) =>
      event.schedule[id];

  factory MatchData.fromJson(Map json) => _$MatchDataFromJson(json);
  Map toJson() => _$MatchDataToJson(this);
}
