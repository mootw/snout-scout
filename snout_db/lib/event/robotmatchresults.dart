import 'package:json_annotation/json_annotation.dart';
import 'package:snout_db/event/matchevent.dart';
import 'package:snout_db/event/pitscoutresult.dart';
import 'package:snout_db/snout_db.dart';

part 'robotmatchresults.g.dart';

@JsonSerializable()
class RobotMatchResults {
  /// The alliance that the robot was on
  final Alliance alliance;

  //Post game survey like pit scouting; but used for scoring too
  final PitScoutResult survey;

  /// List of events this robot did during the match
  final List<MatchEvent> timeline;
  final List<MatchEvent> timelineInterpolated;

  /// Independent data structure that contains all data
  /// of a single robot in a match.
  /// Initializing this object will also pre-calculate an interpolated timeline
  RobotMatchResults(
      {required this.alliance, required this.survey, required this.timeline,})
      : timelineInterpolated = _interpolateTimeline(timeline);

  factory RobotMatchResults.fromJson(Map<String, dynamic> json) =>
      _$RobotMatchResultsFromJson(json);
  Map<String, dynamic> toJson() => _$RobotMatchResultsToJson(this);

  List<MatchEvent> timelineRedNormalized(FieldStyle fieldStyle) =>
      _normalizeRed(timeline, fieldStyle);
  List<MatchEvent> timelineInterpolatedRedNormalized(FieldStyle fieldStyle) =>
      _normalizeRed(timelineInterpolated, fieldStyle);

  //internal function to normalize the timeline as red.
  List<MatchEvent> _normalizeRed(List<MatchEvent> events, FieldStyle fieldStyle) {
    if (alliance == Alliance.blue) {
      return List.generate(events.length, (index) {
        final MatchEvent event = events[index];
        final FieldPosition position = fieldStyle == FieldStyle.rotated
            ? event.position.rotated
            : event.position.mirrored;
        return MatchEvent(
            time: event.time, id: event.id, x: position.x, y: position.y,);
      });
    } else {
      return events;
    }
  }
}

/// attempts to guess where the robot is inbetween the reported positions.
/// Since scouts cannot track everything, we have to make a best guess interpolation.
/// Generally we just linearly interpolate however, if the points are more than some seconds apart
/// we will just teleport the robot to the new position
List<MatchEvent> _interpolateTimeline(List<MatchEvent> timeline) {
  final interpolated = timeline.toList();

  final positions =
      interpolated.where((element) => element.isPositionEvent).toList();
  for (int i = 0; i < positions.length - 1; i++) {
    //Interpolate between them
    final pos1 = positions[i];
    final pos2 = positions[i + 1];

    //Amount of seconds that need to be interpolated
    final width = pos2.time - pos1.time;

    if (width > 8) {
      //Teleport the robot if there is a large gap; too much missing data.
      // POTENTIALLY, it makes sense to add positions for the time stamps that are "SKIPPED"
      // though this implies that there is 'information' which there really is not.
      continue;
    }

    //Do not double include the zero time so start at x=1.
    for (int x = 1; x < width; x++) {
      final newTime = pos1.time + x;
      interpolated.add(MatchEvent.robotPositionEvent(
          time: newTime,
          position: FieldPosition(
              lerp(pos1.time.toDouble(), pos1.position.x, pos2.time.toDouble(),
                  pos2.position.x, newTime.toDouble(),),
              lerp(pos1.time.toDouble(), pos1.position.y, pos2.time.toDouble(),
                  pos2.position.y, newTime.toDouble(),),),),);
    }
  }
  interpolated.sort((a, b) => a.time - b.time);
  return interpolated;
}

/// linear interpolation betweent two points given a time
double lerp(double xa, double ya, double xb, double yb, double t) {
  return ya + ((yb - ya) * ((t - xa) / (xb - xa)));
}
