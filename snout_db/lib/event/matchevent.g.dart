// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'matchevent.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MatchEvent _$MatchEventFromJson(Map<String, dynamic> json) => MatchEvent(
      time: json['time'] as int,
      id: json['id'] as String,
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
    );

Map<String, dynamic> _$MatchEventToJson(MatchEvent instance) =>
    <String, dynamic>{
      'time': instance.time,
      'id': instance.id,
      'x': instance.x,
      'y': instance.y,
    };
