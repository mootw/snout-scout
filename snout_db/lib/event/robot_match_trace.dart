import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:snout_db/event/matchevent.dart';
import 'package:snout_db/snout_chain.dart';

part 'robot_match_trace.g.dart';

@immutable
@JsonSerializable()
class RobotMatchTraceData {
  /// The alliance that the robot was on
  final Alliance alliance;

  /// List of events this robot did during the match
  final List<MatchEvent> timeline;
  final List<MatchEvent> timelineInterpolated;

  /// Independent data structure that contains all data
  /// of a single robot in a match.
  /// Initializing this object will also pre-calculate an interpolated timeline
  RobotMatchTraceData({required this.alliance, required this.timeline})
    : timelineInterpolated = _interpolateTimeline(timeline);

  factory RobotMatchTraceData.fromJson(Map<String, dynamic> json) =>
      _$RobotMatchTraceDataFromJson(json);
  Map<String, dynamic> toJson() => _$RobotMatchTraceDataToJson(this);

  //TODO this is bad code
  List<MatchEvent> timelineBlueNormalized(FieldStyle fieldStyle) =>
      _normalizeBlue(timeline, fieldStyle);
  List<MatchEvent> timelineInterpolatedBlueNormalized(FieldStyle fieldStyle) =>
      _normalizeBlue(timelineInterpolated, fieldStyle);

  //internal function to normalize the timeline as red.
  List<MatchEvent> _normalizeBlue(
    List<MatchEvent> events,
    FieldStyle fieldStyle,
  ) {
    if (alliance == Alliance.red) {
      return List.generate(events.length, (index) {
        final MatchEvent event = events[index];
        final FieldPosition position = fieldStyle == FieldStyle.rotated
            ? event.position.rotated
            : event.position.mirrored;
        return MatchEvent(
          timeMS: event.timeMS,
          id: event.id,
          x: position.x,
          y: position.y,
        );
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

  final positions = interpolated
      .where((element) => element.isPositionEvent)
      .toList();
  for (int i = 0; i < positions.length - 1; i++) {
    //Interpolate between them
    final pos1 = positions[i];
    final pos2 = positions[i + 1];

    //Amount of seconds that need to be interpolated
    final width = pos2.timeMS - pos1.timeMS;

    // 8 seconds
    if (width > 8000) {
      //Teleport the robot if there is a large gap; too much missing data.
      // POTENTIALLY, it makes sense to add positions for the time stamps that are "SKIPPED"
      // though this implies that there is 'information' which there really is not.
      continue;
    }

    // TODO interpolate based on distance rather than time
    // BE CAREFUL this has huge performance impact (compute and memory), since the interpolated timeline is used for most all calculations and visuals.
    //interpolate every 200 milliseconds. There needs to be at least 1000 ms since old code relied on there being 1 event per integer second
    const interpolationFrequency = 200;
    for (
      int x = interpolationFrequency;
      x < width;
      x += interpolationFrequency
    ) {
      final newTime = pos1.timeMS + x;
      interpolated.add(
        MatchEvent.robotPositionEvent(
          time: Duration(milliseconds: newTime),
          position: FieldPosition(
            lerp(
              pos1.timeMS.toDouble(),
              pos1.position.x,
              pos2.timeMS.toDouble(),
              pos2.position.x,
              newTime.toDouble(),
            ),
            lerp(
              pos1.timeMS.toDouble(),
              pos1.position.y,
              pos2.timeMS.toDouble(),
              pos2.position.y,
              newTime.toDouble(),
            ),
          ),
        ),
      );
    }
  }
  interpolated.sort((a, b) => a.timeMS.compareTo(b.timeMS));
  return interpolated;
}

/// linear interpolation betweent two points given a time
double lerp(double xa, double ya, double xb, double yb, double t) {
  return ya + ((yb - ya) * ((t - xa) / (xb - xa)));
}
