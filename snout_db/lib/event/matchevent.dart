import 'package:json_annotation/json_annotation.dart';
import 'package:snout_db/config/matcheventconfig.dart';
import 'package:snout_db/snout_db.dart';

part 'matchevent.g.dart';

/// Match event that is recorded to the database
@JsonSerializable()
class MatchEvent {
  int time;
  String id;
  String label;

  //x, y position on the field
  double x;
  double y;
  //red team normalized x y position on the field
  double nx;
  double ny;

  MatchEvent(
      //Default match event time to zero to allow for defining an event in the season config
      //without a time, since that wouldn't make sense.
      {required this.time,
      required this.x,
      required this.y,
      //TODO instead of storing the normalized position, store the team?
      required this.nx,
      required this.ny,
      required this.id,
      required this.label,
      });

  //Generates an event from the config template
  MatchEvent.fromEventConfig(
      {required MatchEventConfig event,
      required FieldPosition position,
      required FieldPosition redNormalizedPosition,
      required this.time})
      : id = event.id,
        label = event.label,
        x = position.x,
        y = position.y,
        nx = redNormalizedPosition.x,
        ny = redNormalizedPosition.y;

  //Generates a new robot position event
  MatchEvent.robotPositionEvent(
      {required this.time, required FieldPosition position, required FieldPosition redNormalizedPosition})
      : id = "robot_position",
        label = "Robot Position",
        x = position.x,
        y = position.y,
        nx = redNormalizedPosition.x,
        ny = redNormalizedPosition.y;

  factory MatchEvent.fromJson(Map<String, dynamic> json) =>
      _$MatchEventFromJson(json);
  Map<String, dynamic> toJson() => _$MatchEventToJson(this);

  FieldPosition get position => FieldPosition(x, y);
  FieldPosition get positionTeamNormalized => FieldPosition(nx, ny);
  
  bool get isInAuto => time <= 17;
}
