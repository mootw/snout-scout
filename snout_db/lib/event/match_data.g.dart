// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'match_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MatchData _$MatchDataFromJson(Map json) => MatchData(
      results: json['results'] == null
          ? null
          : MatchResultValues.fromJson(json['results'] as Map),
      properties: (json['properties'] as Map?)?.map(
            (k, e) => MapEntry(k as String, e),
          ) ??
          const {},
      robot: (json['robot'] as Map).map(
        (k, e) => MapEntry(k as String,
            RobotMatchResults.fromJson(Map<String, dynamic>.from(e as Map))),
      ),
    );

Map<String, dynamic> _$MatchDataToJson(MatchData instance) => <String, dynamic>{
      'results': instance.results?.toJson(),
      'properties': instance.properties,
      'robot': instance.robot.map((k, e) => MapEntry(k, e.toJson())),
    };
