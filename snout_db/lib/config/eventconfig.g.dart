// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'eventconfig.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EventConfig _$EventConfigFromJson(Map<String, dynamic> json) => EventConfig(
      team: json['team'] as int,
      season: json['season'] as int,
      fieldStyle: $enumDecode(_$FieldStyleEnumMap, json['fieldStyle']),
      pitscouting: (json['pitscouting'] as List<dynamic>)
          .map((e) => SurveyItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      matchscouting:
          MatchScouting.fromJson(json['matchscouting'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$EventConfigToJson(EventConfig instance) =>
    <String, dynamic>{
      'season': instance.season,
      'fieldStyle': _$FieldStyleEnumMap[instance.fieldStyle]!,
      'team': instance.team,
      'pitscouting': instance.pitscouting,
      'matchscouting': instance.matchscouting,
    };

const _$FieldStyleEnumMap = {
  FieldStyle.rotated: 'rotated',
  FieldStyle.mirrored: 'mirrored',
};