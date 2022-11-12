// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'matchevent.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MatchEvent _$MatchEventFromJson(Map<String, dynamic> json) => MatchEvent(
      time: json['time'] as int? ?? 0,
      x: (json['x'] as num?)?.toDouble() ?? 0,
      y: (json['y'] as num?)?.toDouble() ?? 0,
      nx: (json['xn'] as num?)?.toDouble() ?? 0,
      ny: (json['yn'] as num?)?.toDouble() ?? 0,
      id: json['id'] as String,
      label: json['label'] as String,
      values: Map<String, int>.from(json['values'] as Map),
      data: json['data'] as Map<String, dynamic>? ?? const {},
    );

Map<String, dynamic> _$MatchEventToJson(MatchEvent instance) =>
    <String, dynamic>{
      'time': instance.time,
      'id': instance.id,
      'label': instance.label,
      'values': instance.values,
      'x': instance.x,
      'y': instance.y,
      'xn': instance.nx,
      'yn': instance.ny,
      'data': instance.data,
    };
