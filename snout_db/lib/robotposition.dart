import 'dart:math' as math;

//Number between 0 and 1 on both axis
//Positive X is towards the opposing alliance.
//Positive Y is along the alliance wall
//Map is the field boundry.
// (0, 0) is the corner to the left and closest
// to the scoring table.
class RobotPosition {
  double x;
  double y;

  RobotPosition(double posX, double posY)
      : x = math.max(0, math.min(1, (posX * 1000).roundToDouble() / 1000)),
        y = math.max(0, math.min(1, (posY * 1000).roundToDouble() / 1000));

}