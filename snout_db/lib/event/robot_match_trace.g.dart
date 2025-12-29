// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'robot_match_trace.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RobotMatchTraceData _$RobotMatchTraceDataFromJson(Map json) =>
    RobotMatchTraceData(
      alliance: $enumDecode(_$AllianceEnumMap, json['alliance']),
      timeline: (json['timeline'] as List<dynamic>)
          .map((e) => MatchEvent.fromJson(e as Map))
          .toList(),
    );

Map<String, dynamic> _$RobotMatchTraceDataToJson(
  RobotMatchTraceData instance,
) => <String, dynamic>{
  'alliance': _$AllianceEnumMap[instance.alliance]!,
  'timeline': instance.timeline.map((e) => e.toJson()).toList(),
};

const _$AllianceEnumMap = {
  Alliance.red: 'red',
  Alliance.blue: 'blue',
  Alliance.tie: 'tie',
};
