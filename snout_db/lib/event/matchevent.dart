import 'package:collection/collection.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:snout_db/config/matcheventconfig.dart';
import 'package:snout_db/snout_db.dart';

part 'matchevent.g.dart';

/// Match event that is recorded to the database
@JsonSerializable()
class MatchEvent {
  final int time;
  final String id;

  //x, y position on the field
  final double x;
  final double y;

  const MatchEvent({
    required this.time,
    required this.id,
    required this.x,
    required this.y,
  });

  //Generates an event from the config template
  MatchEvent.fromEventConfig(
      {required MatchEventConfig event,
      required FieldPosition position,
      required this.time})
      : id = event.id,
        x = position.x,
        y = position.y;

  //Generates a new robot position event
  MatchEvent.robotPositionEvent(
      {required this.time,
      required FieldPosition position})
      : id = "robot_position",
        x = position.x,
        y = position.y;

  factory MatchEvent.fromJson(Map<String, dynamic> json) =>
      _$MatchEventFromJson(json);
  Map<String, dynamic> toJson() => _$MatchEventToJson(this);

  FieldPosition get position => FieldPosition(x, y);

  /// Since the timer is floored to seconds, this includes up to 18.
  bool get isInAuto => time <= 17; 
  bool get isPositionEvent => id == "robot_position";

  /// Gets the event label from a specific event config. It will return Position for all position events regardless
  /// This setup while it does reduce the database redundancy can be problematic in the future if localization is desired for robot position event label
  String getLabelFromConfig(EventConfig config) => isPositionEvent
      ? "Position"
      : config.matchscouting.events
              .firstWhereOrNull((element) => element.id == id)
              ?.label ??
          id;

  String? getColorFromConfig(EventConfig config) => config.matchscouting.events
      .firstWhereOrNull((element) => element.id == id)
      ?.color;

  @override
  String toString() => 't:${time} id:${id} pos:${position}';
}
