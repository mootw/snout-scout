import 'dart:math' as math;

/// Number between -1 and 1 on both axis, 0,0 is the center of the field
/// Positive X is towards the opposing alliance.
/// Positive Y is along the alliance wall
/// Map is the field boundry.
/// Position is relative to red alliance unless otherwise specified
/// in this situation -1, -1 is the bottom left corner where the field is between
/// the viewer and the admin. -1, 0 is about where red 2 drivers station is.
/// and 1,0 is where blue 2 is
class FieldPosition {

  final double x;
  final double y;

  FieldPosition(double posX, double posY)
      : x = math.max(-1, math.min(1, (posX * 1000).roundToDouble() / 1000)),
        y = math.max(-1, math.min(1, (posY * 1000).roundToDouble() / 1000));

  /// Returns a new position rotated 180 degrees about the origin (center of field).
  /// This can be used to normalize recorded positions to always be as if it was
  /// on one side of the field. Important for analysing things like starting positions.
  FieldPosition get inverted => FieldPosition(-x, -y); 

  /// Returns a new position mirrored across the center of the field dividing the alliances
  /// This can be used to normalize recorded positions to always be as if it was
  /// on one side of the field. Important for analysing things like starting positions.
  FieldPosition get mirrored => FieldPosition(-x, y); 

  @override
  String toString () => "$x, $y";

}