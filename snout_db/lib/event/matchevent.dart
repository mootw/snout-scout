import 'package:collection/collection.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:snout_db/config/matcheventconfig.dart';
import 'package:snout_db/snout_chain.dart';

part 'matchevent.g.dart';

const String robotPositionTag = 'robot_position';

/// Match event that is recorded to the database
@immutable
@JsonSerializable()
class MatchEvent {
  /// Match time from zero in milliseconds
  final int timeMS;

  final String id;

  Duration get timeDuration => Duration(milliseconds: timeMS);

  //x, y position on the field
  final double x;
  final double y;

  const MatchEvent({
    required this.timeMS,
    required this.id,
    required this.x,
    required this.y,
  });

  //Generates an event from the config template
  MatchEvent.fromEventConfig({
    required MatchEventConfig event,
    required FieldPosition position,
    required Duration time,
  }) : timeMS = time.inMilliseconds,
       id = event.id,
       x = position.x,
       y = position.y;

  //Generates a new robot position event
  MatchEvent.robotPositionEvent({
    required Duration time,
    required FieldPosition position,
  }) : timeMS = time.inMilliseconds,
       id = robotPositionTag,
       x = position.x,
       y = position.y;

  factory MatchEvent.fromJson(Map json) => _$MatchEventFromJson(json);
  Map toJson() => _$MatchEventToJson(this);

  FieldPosition get position => FieldPosition(x, y);

  bool get isPositionEvent => id == robotPositionTag;

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
  String toString() => 't:$timeMS id:$id pos:$position';
}
