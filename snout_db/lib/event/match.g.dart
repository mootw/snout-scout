// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'match.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FRCMatch _$FRCMatchFromJson(Map json) => FRCMatch(
      description: json['description'] as String,
      scheduledTime: DateTime.parse(json['scheduledTime'] as String),
      red: (json['red'] as List<dynamic>).map((e) => e as int).toList(),
      blue: (json['blue'] as List<dynamic>).map((e) => e as int).toList(),
      results: json['results'] == null
          ? null
          : MatchResultValues.fromJson(json['results'] as Map),
      robot: (json['robot'] as Map).map(
        (k, e) => MapEntry(k as String,
            RobotMatchResults.fromJson(Map<String, dynamic>.from(e as Map))),
      ),
    );

Map<String, dynamic> _$FRCMatchToJson(FRCMatch instance) => <String, dynamic>{
      'description': instance.description,
      'scheduledTime': instance.scheduledTime.toIso8601String(),
      'red': instance.red,
      'blue': instance.blue,
      'results': instance.results?.toJson(),
      'robot': instance.robot.map((k, e) => MapEntry(k, e.toJson())),
    };
