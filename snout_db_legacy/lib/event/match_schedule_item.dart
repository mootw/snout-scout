import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:snout_db_legacy/event/frcevent.dart';
import 'package:snout_db_legacy/event/match_data.dart';
import 'package:snout_db_legacy/game.dart';

part 'match_schedule_item.g.dart';

@immutable
@JsonSerializable()
class MatchScheduleItem implements Comparable<MatchScheduleItem> {
  /// Unique identifier for this match
  final String id;

  ///aka the match name (Qualitication 1, Quarters 3 Match 1, Semifinals 2)
  final String label;

  ///time the match was scheduled for
  final DateTime scheduledTime;

  ///list of scheduled blue teams
  final List<int> blue;

  /// list of scheduled red teams
  final List<int> red;

  const MatchScheduleItem({
    required this.id,
    required this.label,
    required this.scheduledTime,
    required this.red,
    required this.blue,
  });

  factory MatchScheduleItem.fromJson(Map json) =>
      _$MatchScheduleItemFromJson(json);
  Map toJson() => _$MatchScheduleItemToJson(this);

  //Default sorting should be based on match time, and then hashCode
  @override
  int compareTo(MatchScheduleItem other) {
    final timeDiff =
        scheduledTime.difference(other.scheduledTime).inMicroseconds;
    if (timeDiff == 0) {
      return hashCode.compareTo(other.hashCode);
    } else {
      return timeDiff;
    }
  }

  Alliance getAllianceOf(int team) =>
      red.contains(team) ? Alliance.red : Alliance.blue;

  bool isScheduledToHaveTeam(int team) =>
      red.contains(team) || blue.contains(team);

  /// difference between the time that the match was scheduled and the actual time
  /// the match started
  Duration? delayFromScheduledTime(FRCEvent event) =>
      event.matches[id]?.results?.time.difference(scheduledTime);

  /// is true when the match has match results, which means the match is complete
  bool isComplete(FRCEvent event) => getData(event)?.results != null;

  MatchData? getData(FRCEvent event) => event.matches[id];
}
