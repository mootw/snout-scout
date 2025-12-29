// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'matchscouting.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MatchScouting _$MatchScoutingFromJson(Map json) => MatchScouting(
  events:
      (json['events'] as List<dynamic>?)
          ?.map(
            (e) =>
                MatchEventConfig.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList() ??
      const [],
  processes:
      (json['processes'] as List<dynamic>?)
          ?.map(
            (e) => MatchResultsProcess.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList() ??
      const [],
  survey:
      (json['survey'] as List<dynamic>?)
          ?.map(
            (e) => DataItemSchema.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList() ??
      const [],
  properties:
      (json['properties'] as List<dynamic>?)
          ?.map(
            (e) => DataItemSchema.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList() ??
      const [],
);

Map<String, dynamic> _$MatchScoutingToJson(MatchScouting instance) =>
    <String, dynamic>{
      'events': instance.events.map((e) => e.toJson()).toList(),
      'processes': instance.processes.map((e) => e.toJson()).toList(),
      'survey': instance.survey.map((e) => e.toJson()).toList(),
      'properties': instance.properties.map((e) => e.toJson()).toList(),
    };
