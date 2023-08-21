// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'eventconfig.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EventConfig _$EventConfigFromJson(Map<String, dynamic> json) => EventConfig(
      name: json['name'] as String,
      team: json['team'] as int,
      season: json['season'] as int,
      tbaEventId: json['tbaEventId'] as String?,
      tbaSecretKey: json['tbaSecretKey'] as String?,
      fieldStyle:
          $enumDecodeNullable(_$FieldStyleEnumMap, json['fieldStyle']) ??
              FieldStyle.rotated,
      pitscouting: (json['pitscouting'] as List<dynamic>?)
              ?.map((e) => SurveyItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      matchscouting: json['matchscouting'] == null
          ? const MatchScouting()
          : MatchScouting.fromJson(
              json['matchscouting'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$EventConfigToJson(EventConfig instance) =>
    <String, dynamic>{
      'name': instance.name,
      'season': instance.season,
      'tbaEventId': instance.tbaEventId,
      'tbaSecretKey': instance.tbaSecretKey,
      'fieldStyle': _$FieldStyleEnumMap[instance.fieldStyle]!,
      'team': instance.team,
      'pitscouting': instance.pitscouting,
      'matchscouting': instance.matchscouting,
    };

const _$FieldStyleEnumMap = {
  FieldStyle.rotated: 'rotated',
  FieldStyle.mirrored: 'mirrored',
};
