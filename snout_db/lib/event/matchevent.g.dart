// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'matchevent.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MatchEvent _$MatchEventFromJson(Map<String, dynamic> json) => MatchEvent(
      time: json['time'] as int,
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      nx: (json['nx'] as num).toDouble(),
      ny: (json['ny'] as num).toDouble(),
      id: json['id'] as String,
    );

Map<String, dynamic> _$MatchEventToJson(MatchEvent instance) =>
    <String, dynamic>{
      'time': instance.time,
      'id': instance.id,
      'x': instance.x,
      'y': instance.y,
      'nx': instance.nx,
      'ny': instance.ny,
    };
