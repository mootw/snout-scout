// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'match.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FRCMatch _$FRCMatchFromJson(Map<String, dynamic> json) => FRCMatch(
      description: json['description'] as String,
      scheduledTime: DateTime.parse(json['scheduledTime'] as String),
      red: (json['red'] as List<dynamic>).map((e) => e as int).toList(),
      blue: (json['blue'] as List<dynamic>).map((e) => e as int).toList(),
      results: json['results'] == null
          ? null
          : MatchResultValues.fromJson(json['results'] as Map<String, dynamic>),
      robot: (json['robot'] as Map<String, dynamic>).map(
        (k, e) =>
            MapEntry(k, RobotMatchResults.fromJson(e as Map<String, dynamic>)),
      ),
    );

Map<String, dynamic> _$FRCMatchToJson(FRCMatch instance) => <String, dynamic>{
      'description': instance.description,
      'scheduledTime': instance.scheduledTime.toIso8601String(),
      'red': instance.red,
      'blue': instance.blue,
      'results': instance.results,
      'robot': instance.robot,
    };
