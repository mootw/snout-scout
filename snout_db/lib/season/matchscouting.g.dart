// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'matchscouting.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MatchScouting _$MatchScoutingFromJson(Map<String, dynamic> json) =>
    MatchScouting(
      auto: (json['auto'] as List<dynamic>)
          .map((e) => MatchEvent.fromJson(e as Map<String, dynamic>))
          .toList(),
      teleop: (json['teleop'] as List<dynamic>)
          .map((e) => MatchEvent.fromJson(e as Map<String, dynamic>))
          .toList(),
      postgame: (json['postgame'] as List<dynamic>)
          .map((e) => PitSurveyItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      scoring:
          (json['scoring'] as List<dynamic>).map((e) => e as String).toList(),
    );

Map<String, dynamic> _$MatchScoutingToJson(MatchScouting instance) =>
    <String, dynamic>{
      'auto': instance.auto,
      'teleop': instance.teleop,
      'postgame': instance.postgame,
      'scoring': instance.scoring,
    };
