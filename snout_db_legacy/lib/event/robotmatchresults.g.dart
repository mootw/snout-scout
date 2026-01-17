// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'robotmatchresults.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RobotMatchResults _$RobotMatchResultsFromJson(Map json) => RobotMatchResults(
  alliance: $enumDecode(_$AllianceEnumMap, json['alliance']),
  survey: Map<String, dynamic>.from(json['survey'] as Map),
  timeline:
      (json['timeline'] as List<dynamic>)
          .map((e) => MatchEvent.fromJson(e as Map))
          .toList(),
);

Map<String, dynamic> _$RobotMatchResultsToJson(RobotMatchResults instance) =>
    <String, dynamic>{
      'alliance': _$AllianceEnumMap[instance.alliance]!,
      'survey': instance.survey,
      'timeline': instance.timeline.map((e) => e.toJson()).toList(),
    };

const _$AllianceEnumMap = {
  Alliance.red: 'red',
  Alliance.blue: 'blue',
  Alliance.tie: 'tie',
};
