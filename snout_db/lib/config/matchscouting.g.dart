// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'matchscouting.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MatchScouting _$MatchScoutingFromJson(Map<String, dynamic> json) =>
    MatchScouting(
      events: (json['events'] as List<dynamic>)
          .map((e) => MatchEventConfig.fromJson(e as Map<String, dynamic>))
          .toList(),
      postgame: (json['postgame'] as List<dynamic>)
          .map((e) => SurveyItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      scoring:
          (json['scoring'] as List<dynamic>).map((e) => e as String).toList(),
    );

Map<String, dynamic> _$MatchScoutingToJson(MatchScouting instance) =>
    <String, dynamic>{
      'events': instance.events,
      'postgame': instance.postgame,
      'scoring': instance.scoring,
    };
