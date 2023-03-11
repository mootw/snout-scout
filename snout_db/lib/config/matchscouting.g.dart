// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'matchscouting.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MatchScouting _$MatchScoutingFromJson(Map<String, dynamic> json) =>
    MatchScouting(
      events: (json['events'] as List<dynamic>?)
              ?.map((e) => MatchEventConfig.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      processes: (json['processes'] as List<dynamic>?)
              ?.map((e) =>
                  MatchResultsProcess.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      postgame: (json['postgame'] as List<dynamic>?)
              ?.map((e) => SurveyItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      scoring: (json['scoring'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const ['points', 'rp'],
    );

Map<String, dynamic> _$MatchScoutingToJson(MatchScouting instance) =>
    <String, dynamic>{
      'events': instance.events,
      'processes': instance.processes,
      'postgame': instance.postgame,
      'scoring': instance.scoring,
    };
