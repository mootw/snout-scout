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
  //red team normalized x y position on the field
  double nx;
  double ny;

  Map<String, dynamic> data; //This depends on the type value

  MatchEvent(
      //Default match event time to zero to allow for defining an event in the season config
      //without a time, since that wouldn't make sense.
      {this.time = 0,
      this.x = 0,
      this.y = 0,
      this.nx = 0,
      this.ny = 0,
      required this.id,
      required this.label,
      required this.values,
      //Allow for data to not be populated when defining it in the season config. Generally
      //this value is populated at runtime when saving an instance of an event
      this.data = const {}});

  MatchEvent.fromEventWithTime(
      {required MatchEvent event,
      required FieldPosition position,
      required FieldPosition redNormalizedPosition,
      required this.time,
      this.data = const <String, dynamic>{}})
      : id = event.id,
        label = event.label,
        x = position.x,
        y = position.y,
        nx = redNormalizedPosition.x,
        ny = redNormalizedPosition.y,
        values = event.values;

  MatchEvent.robotPositionEvent(
      {required this.time, required FieldPosition position, required FieldPosition redNormalizedPosition})
      : id = "robot_position",
        label = "Robot Position",
        x = position.x,
        y = position.y,
        nx = redNormalizedPosition.x,
        ny = redNormalizedPosition.y,
        data = {},
        values = {};

  factory MatchEvent.fromJson(Map<String, dynamic> json) =>
      _$MatchEventFromJson(json);
  Map<String, dynamic> toJson() => _$MatchEventToJson(this);

  double getDataNumber(String key) => data[key].toDouble();

  FieldPosition get position => FieldPosition(x, y);
  FieldPosition get positionTeamNormalized => FieldPosition(nx, ny);
  
  bool get isInAuto => time <= 17;
}
