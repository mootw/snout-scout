import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:snout_db/event/dynamic_property.dart';
import 'package:snout_db/event/matchresults.dart';
import 'package:snout_db/event/robotmatchresults.dart';
import 'package:snout_db/game.dart';

part 'match.g.dart';

@immutable
@JsonSerializable()
class FRCMatch implements Comparable<FRCMatch> {
  ///aka the match name (Qualitication 1, Quarters 3 Match 1, Semifinals 2)
  final String description;

  ///time the match was scheduled for
  final DateTime scheduledTime;

  ///list of scheduled blue teams
  final List<int> blue;

  /// list of scheduled red teams
  final List<int> red;

  ///results of the match (null if the match has not been played)
  final MatchResultValues? results;

  /// values stored on a per match basis. like pit scouting for a match
  final DynamicProperties? properties;

  /// Performance of each robot during the match
  /// this map might include surrogate robots (aka robots that are not in the union of the scheduled teams)
  final Map<String, RobotMatchResults> robot;

  const FRCMatch({
    required this.description,
    required this.scheduledTime,
    required this.red,
    required this.blue,
    required this.results,
    // For backwards compatibility
    this.properties = const {},
    required this.robot,
  });

  factory FRCMatch.fromJson(Map json) => _$FRCMatchFromJson(json);
  Map toJson() => _$FRCMatchToJson(this);

  //Default sorting should be based on match time, and then hashCode
  @override
  int compareTo(FRCMatch other) {
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
  Duration? get delayFromScheduledTime =>
      results?.time.difference(scheduledTime);

  /// is true when the match has match results, which means the match is complete
  bool get isComplete => results != null;
}
