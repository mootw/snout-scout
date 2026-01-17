// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'match_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MatchData _$MatchDataFromJson(Map json) => MatchData(
  robot: (json['robot'] as Map).map(
    (k, e) => MapEntry(
      k as String,
      RobotMatchTraceData.fromJson(Map<String, dynamic>.from(e as Map)),
    ),
  ),
);

Map<String, dynamic> _$MatchDataToJson(MatchData instance) => <String, dynamic>{
  'robot': instance.robot.map((k, e) => MapEntry(k, e.toJson())),
};
