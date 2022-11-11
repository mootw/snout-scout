import 'package:json_annotation/json_annotation.dart';
import 'package:snout_db/snout_db.dart';

part 'matchevent.g.dart';

@JsonSerializable()
class MatchEvent {
  int time;
  String id;
  String label;
  Map<String, int> values;

  //x, y position on the field
  double x;
  double y;
  //team normalized x y position on the field
  double? xn;
  double? yn;

  Map<String, dynamic> data; //This depends on the type value

  MatchEvent(
      //Default match event time to zero to allow for defining an event in the season config
      //without a time, since that wouldn't make sense.
      {this.time = 0,
      this.x = 0,
      this.y = 0,
      this.xn = 0,
      this.yn = 0,
      required this.id,
      required this.label,
      required this.values,
      //Allow for data to not be populated when defining it in the season config. Generally
      //this value is populated at runtime when saving an instance of an event
      this.data = const {}});

  MatchEvent.fromEventWithTime(
      {required MatchEvent event,
      required RobotPosition position,
      required this.time,
      this.data = const <String, dynamic>{}})
      : id = event.id,
        label = event.label,
        x = position.x,
        y = position.y,
        values = event.values;

  MatchEvent.robotPositionEvent(
      {required this.time, required double x, required double y})
      : id = "robot_position",
        label = "Robot Position",
        x = x,
        y = y,
        data = {},
        values = {};

  factory MatchEvent.fromJson(Map<String, dynamic> json) =>
      _$MatchEventFromJson(json);
  Map<String, dynamic> toJson() => _$MatchEventToJson(this);

  double getDataNumber(String key) => data[key].toDouble();

  RobotPosition get position => RobotPosition(x, y);
  RobotPosition? get positionTeamNormalized => xn != null && yn != null ? RobotPosition(xn!, yn!) : null;
}
