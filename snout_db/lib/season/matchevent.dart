import 'package:collection/collection.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:snout_db/snout_db.dart';

part 'matchevent.g.dart';

@JsonSerializable()
class MatchEvent {
  int time;
  String id;
  String label;
  String type;
  Map<String, int> values;

  Map<String, dynamic> data; //This depends on the type value

  MatchEvent(
      //Default match event time to zero to allow for defining an event in the season config
      //without a time, since that wouldn't make sense.
      {this.time = 0,
      required this.id,
      required this.label,
      required this.type,
      required this.values,
      //Allow for data to not be populated when defining it in the season config. Generally
      //this value is populated at runtime when saving an instance of an event
      this.data = const {}});

  MatchEvent.fromEventWithTime(
      {required MatchEvent event,
      required this.time,
      this.data = const <String, dynamic>{}})
      : id = event.id,
        label = event.label,
        type = event.type,
        values = event.values;

  MatchEvent.robotPositionEvent(
      {required this.time, required double x, required double y})
      : id = "robot_position",
        label = "Robot Position",
        type = "robot_position",
        data = {"x": x, "y": y},
        values = {};

  factory MatchEvent.fromJson(Map<String, dynamic> json) =>
      _$MatchEventFromJson(json);
  Map<String, dynamic> toJson() => _$MatchEventToJson(this);

  double getNumber(String key) => data[key].toDouble();

  RobotPosition? getEventPosition (List<MatchEvent> events) {
    final event = events.lastWhereOrNull((event) => event.time <= time && event.id == "robot_position");
    if(event != null) {
      return RobotPosition.fromMatchEvent(event);
    }
    return null;
  }
}
