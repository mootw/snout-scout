// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'matcheventconfig.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MatchEventConfig _$MatchEventConfigFromJson(Map<String, dynamic> json) =>
    MatchEventConfig(
      id: json['id'] as String,
      mode: $enumDecode(_$MatchSegmentEnumMap, json['mode']),
      label: json['label'] as String,
    );

Map<String, dynamic> _$MatchEventConfigToJson(MatchEventConfig instance) =>
    <String, dynamic>{
      'id': instance.id,
      'label': instance.label,
      'mode': _$MatchSegmentEnumMap[instance.mode]!,
    };

const _$MatchSegmentEnumMap = {
  MatchSegment.auto: 'auto',
  MatchSegment.teleop: 'teleop',
  MatchSegment.both: 'both',
};
