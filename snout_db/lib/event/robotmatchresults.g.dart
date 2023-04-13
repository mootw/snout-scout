// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'robotmatchresults.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RobotMatchResults _$RobotMatchResultsFromJson(Map<String, dynamic> json) =>
    RobotMatchResults(
      alliance: $enumDecode(_$AllianceEnumMap, json['alliance']),
      survey: json['survey'] as Map<String, dynamic>,
      timeline: (json['timeline'] as List<dynamic>)
          .map((e) => MatchEvent.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$RobotMatchResultsToJson(RobotMatchResults instance) =>
    <String, dynamic>{
      'alliance': _$AllianceEnumMap[instance.alliance]!,
      'survey': instance.survey,
      'timeline': instance.timeline,
    };

const _$AllianceEnumMap = {
  Alliance.red: 'red',
  Alliance.blue: 'blue',
  Alliance.tie: 'tie',
};
