// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'matcheventconfig.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MatchEventConfig _$MatchEventConfigFromJson(Map<String, dynamic> json) =>
    MatchEventConfig(
      id: json['id'] as String,
      label: json['label'] as String,
      color: json['color'] as String?,
    );

Map<String, dynamic> _$MatchEventConfigToJson(MatchEventConfig instance) =>
    <String, dynamic>{
      'id': instance.id,
      'label': instance.label,
      'color': instance.color,
    };
