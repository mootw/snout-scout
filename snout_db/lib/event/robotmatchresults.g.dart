// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'robotmatchresults.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RobotMatchResults _$RobotMatchResultsFromJson(Map<String, dynamic> json) =>
    RobotMatchResults(
      timeline: (json['timeline'] as List<dynamic>)
          .map((e) => MatchEvent.fromJson(e as Map<String, dynamic>))
          .toList(),
      survey: json['survey'] as Map<String, dynamic>,
    );

Map<String, dynamic> _$RobotMatchResultsToJson(RobotMatchResults instance) =>
    <String, dynamic>{
      'timeline': instance.timeline,
      'survey': instance.survey,
    };
