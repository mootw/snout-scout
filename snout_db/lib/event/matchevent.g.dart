// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'matchevent.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MatchEvent _$MatchEventFromJson(Map json) => MatchEvent(
  timeMS: (json['timeMS'] as num).toInt(),
  id: json['id'] as String,
  x: (json['x'] as num).toDouble(),
  y: (json['y'] as num).toDouble(),
);

Map<String, dynamic> _$MatchEventToJson(MatchEvent instance) =>
    <String, dynamic>{
      'timeMS': instance.timeMS,
      'id': instance.id,
      'x': instance.x,
      'y': instance.y,
    };
