// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'match_schedule_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MatchScheduleItem _$MatchScheduleItemFromJson(Map json) => MatchScheduleItem(
      id: json['id'] as String,
      label: json['label'] as String,
      scheduledTime: DateTime.parse(json['scheduledTime'] as String),
      red: (json['red'] as List<dynamic>)
          .map((e) => (e as num).toInt())
          .toList(),
      blue: (json['blue'] as List<dynamic>)
          .map((e) => (e as num).toInt())
          .toList(),
    );

Map<String, dynamic> _$MatchScheduleItemToJson(MatchScheduleItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'label': instance.label,
      'scheduledTime': instance.scheduledTime.toIso8601String(),
      'blue': instance.blue,
      'red': instance.red,
    };
