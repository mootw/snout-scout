// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'eventconfig.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EventConfig _$EventConfigFromJson(Map json) => EventConfig(
  name: json['name'] as String,
  team: (json['team'] as num).toInt(),
  tbaEventId: json['tbaEventId'] as String?,
  tbaSecretKey: json['tbaSecretKey'] as String?,
  fieldStyle:
      $enumDecodeNullable(_$FieldStyleEnumMap, json['fieldStyle']) ??
      FieldStyle.rotated,
  pitscouting:
      (json['pitscouting'] as List<dynamic>?)
          ?.map(
            (e) => DataItemSchema.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList() ??
      const [],
  pit:
      (json['pit'] as List<dynamic>?)
          ?.map(
            (e) => DataItemSchema.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList() ??
      const [
        DataItemSchema(
          id: 'pit_map',
          label: 'Pit Map',
          type: DataItemType.picture,
          docs: 'Image of the Pit Map',
        ),
        DataItemSchema(
          id: 'docs',
          label: 'Docs',
          type: DataItemType.text,
          docs: 'Event schedule and other important info',
        ),
        DataItemSchema(
          id: 'fresh_battery',
          label: 'Fresh Battery',
          type: DataItemType.toggle,
        ),
      ],
  matchperiods:
      (json['matchperiods'] as List<dynamic>?)
          ?.map(
            (e) =>
                MatchPeriodConfig.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList() ??
      const [
        MatchPeriodConfig(id: 'auto', label: 'Auto', durationSeconds: 17),
        MatchPeriodConfig(id: 'teleop', label: 'Teleop', durationSeconds: 135),
      ],
  matchscouting: json['matchscouting'] == null
      ? const MatchScouting()
      : MatchScouting.fromJson(
          Map<String, dynamic>.from(json['matchscouting'] as Map),
        ),
  fieldImage: json['fieldImage'] as String,
);

Map<String, dynamic> _$EventConfigToJson(EventConfig instance) =>
    <String, dynamic>{
      'name': instance.name,
      'tbaEventId': instance.tbaEventId,
      'tbaSecretKey': instance.tbaSecretKey,
      'fieldStyle': _$FieldStyleEnumMap[instance.fieldStyle]!,
      'team': instance.team,
      'pitscouting': instance.pitscouting.map((e) => e.toJson()).toList(),
      'pit': instance.pit.map((e) => e.toJson()).toList(),
      'matchscouting': instance.matchscouting.toJson(),
      'matchperiods': instance.matchperiods.map((e) => e.toJson()).toList(),
      'fieldImage': instance.fieldImage,
    };

const _$FieldStyleEnumMap = {
  FieldStyle.rotated: 'rotated',
  FieldStyle.mirrored: 'mirrored',
};
