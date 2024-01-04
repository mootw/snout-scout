// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'eventconfig.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EventConfig _$EventConfigFromJson(Map json) => EventConfig(
      name: json['name'] as String,
      team: json['team'] as int,
      fieldImage: json['fieldImage'] as String,
      tbaEventId: json['tbaEventId'] as String?,
      tbaSecretKey: json['tbaSecretKey'] as String?,
      fieldStyle:
          $enumDecodeNullable(_$FieldStyleEnumMap, json['fieldStyle']) ??
              FieldStyle.rotated,
      pitscouting: (json['pitscouting'] as List<dynamic>?)
              ?.map((e) =>
                  SurveyItem.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          const [],
      matchscouting: json['matchscouting'] == null
          ? const MatchScouting()
          : MatchScouting.fromJson(
              Map<String, dynamic>.from(json['matchscouting'] as Map)),
      docs: json['docs'] as String? ?? '',
    );

Map<String, dynamic> _$EventConfigToJson(EventConfig instance) =>
    <String, dynamic>{
      'name': instance.name,
      'tbaEventId': instance.tbaEventId,
      'tbaSecretKey': instance.tbaSecretKey,
      'fieldStyle': _$FieldStyleEnumMap[instance.fieldStyle]!,
      'team': instance.team,
      'pitscouting': instance.pitscouting.map((e) => e.toJson()).toList(),
      'matchscouting': instance.matchscouting.toJson(),
      'docs': instance.docs,
      'fieldImage': instance.fieldImage,
    };

const _$FieldStyleEnumMap = {
  FieldStyle.rotated: 'rotated',
  FieldStyle.mirrored: 'mirrored',
};
