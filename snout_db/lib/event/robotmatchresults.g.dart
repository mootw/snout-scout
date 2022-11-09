// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'robotmatchresults.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RobotMatchResults _$RobotMatchResultFromJson(Map<String, dynamic> json) =>
    RobotMatchResults(
      timeline: (json['timeline'] as List<dynamic>)
          .map((e) => MatchEvent.fromJson(e as Map<String, dynamic>))
          .toList(),
      survey: (json['survey'] as List<dynamic>)
          .map((e) => e as Map<String, dynamic>)
          .toList(),
    );

Map<String, dynamic> _$RobotMatchResultToJson(RobotMatchResults instance) =>
    <String, dynamic>{
      'timeline': instance.timeline,
      'survey': instance.survey,
    };
