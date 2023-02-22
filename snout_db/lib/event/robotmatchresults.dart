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

  factory RobotMatchResults.fromJson(Map<String, dynamic> json) =>
      _$RobotMatchResultsFromJson(json);
  Map<String, dynamic> toJson() => _$RobotMatchResultsToJson(this);

  /// attempts to guess where the robot is inbetween the reported positions.
  /// Since scouts cannot track everything, we have to make a best guess interpolation.
  /// Generally we just linearly interpolate however, if the points are more than 15 seconds apart
  /// we will just teleport the robot to the new position
  List<MatchEvent> get timelineInterpolated {
    var interpolated = timeline.toList();

    final positions =
        timeline.where((element) => element.id == "robot_position").toList();
    for (int i = 0; i < positions.length - 1; i++) {
      //Interpolate between them
      final pos1 = positions[i];
      final pos2 = positions[i + 1];

      //Amount of seconds that need to be interpolated
      final width = pos2.time - pos1.time;

      if (width > 15) {
        //Just teleport the robot if there is a 15 second gap to interpolate, too much missing data.
        continue;
      }

      //Do not double include the zero time so start at x=1.
      for (int x = 1; x < width; x++) {
        final newTime = pos1.time + x;
        interpolated.add(MatchEvent.robotPositionEvent(
            time: newTime,
            redNormalizedPosition: FieldPosition(
                lerp(
                    pos1.time.toDouble(),
                    pos1.positionTeamNormalized.x,
                    pos2.time.toDouble(),
                    pos2.positionTeamNormalized.x,
                    newTime.toDouble()),
                lerp(
                    pos1.time.toDouble(),
                    pos1.positionTeamNormalized.y,
                    pos2.time.toDouble(),
                    pos2.positionTeamNormalized.y,
                    newTime.toDouble())),
            position: FieldPosition(
                lerp(pos1.time.toDouble(), pos1.position.x,
                    pos2.time.toDouble(), pos2.position.x, newTime.toDouble()),
                lerp(
                    pos1.time.toDouble(),
                    pos1.position.y,
                    pos2.time.toDouble(),
                    pos2.position.y,
                    newTime.toDouble()))));
      }
    }
    interpolated.sort((a, b) => a.time - b.time);
    return interpolated;
  }
}

double lerp(double xa, double ya, double xb, double yb, double t) {
  return ya + ((yb - ya) * ((t - xa) / (xb - xa)));
}
