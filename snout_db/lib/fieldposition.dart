import 'package:meta/meta.dart';

/// Number between -1 and 1 on both axis, 0,0 is the center of the field
/// Positive X is towards the opposing alliance.
/// Positive Y is along the alliance wall
/// Map is the field boundry.
/// Position is relative to red alliance unless otherwise specified
/// in this situation -1, -1 is the bottom left corner where the field is between
/// the viewer and the admin. -1, 0 is about where red 2 drivers station is.
/// and 1,0 is where blue 2 is
/// the values are rounded to a realistic accuracy
@immutable
class FieldPosition {
  final double x;
  final double y;

  /// Rounded, yields a resolution of about 8cm
  FieldPosition(double x, double y)
      : x = (x * 200).roundToDouble() / 200,
        y = (y * 100).roundToDouble() / 100;

  /// Returns a new position rotated 180 degrees about the origin (center of field).
  /// This can be used to normalize recorded positions to always be as if it was
  /// on one side of the field. Important for analysing things like starting positions.
  FieldPosition get rotated => FieldPosition(-x, -y);

  /// Returns a new position mirrored across the center of the field dividing the alliances
  /// This can be used to normalize recorded positions to always be as if it was
  /// on one side of the field. Important for analysing things like starting positions.
  FieldPosition get mirrored => FieldPosition(-x, y);

  @override
  String toString() => "($x, $y)";
}
