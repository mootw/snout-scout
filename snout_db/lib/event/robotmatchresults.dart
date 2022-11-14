import 'package:json_annotation/json_annotation.dart';
import 'package:snout_db/event/pitscoutresult.dart';
import 'package:snout_db/fieldposition.dart';
import 'package:snout_db/event/matchevent.dart';

part 'robotmatchresults.g.dart';

@JsonSerializable()
class RobotMatchResults {
  
  /// List of events this robot did during the match
  List<MatchEvent> timeline;
  //Post game survey like pit scouting; but used for scoring too
  PitScoutResult survey;

  RobotMatchResults({required this.timeline, required this.survey});

  factory RobotMatchResults.fromJson(Map<String, dynamic> json) => _$RobotMatchResultsFromJson(json);
  Map<String, dynamic> toJson() => _$RobotMatchResultsToJson(this);

  List<MatchEvent> timelineInterpolated () {
    var interpolated = timeline.toList();

    final positions = timeline.where((element) => element.id == "robot_position").toList();
    for(int i = 0; i < positions.length - 1; i++) {
      //Interpolate between them
      final pos1 = positions[i];
      final pos2 = positions[i+1];

      //Amount of seconds that need to be interpolated
      final width = pos2.time - pos1.time;
      for(int x = 1; x < width; x++) {
        final newTime = pos1.time + x;
        interpolated.add(MatchEvent.robotPositionEvent(
          time: newTime,
          redNormalizedPosition: FieldPosition(
            lerp(pos1.time.toDouble(), pos1.positionTeamNormalized.x, pos2.time.toDouble(), pos2.positionTeamNormalized.x, newTime.toDouble()),
            lerp(pos1.time.toDouble(), pos1.positionTeamNormalized.y, pos2.time.toDouble(), pos2.positionTeamNormalized.y, newTime.toDouble())
          ),
          position: FieldPosition(
            lerp(pos1.time.toDouble(), pos1.position.x, pos2.time.toDouble(), pos2.position.x, newTime.toDouble()),
            lerp(pos1.time.toDouble(), pos1.position.y, pos2.time.toDouble(), pos2.position.y, newTime.toDouble()))
          ));
      }
    }
    return interpolated..sort((a, b) => a.time - b.time);
  }
}

double lerp (double xa, double ya, double xb, double yb, double t) {
  return ya + ((yb - ya) * ((t - xa) / (xb - xa)));
}
