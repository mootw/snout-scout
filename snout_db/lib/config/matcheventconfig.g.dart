// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'matcheventconfig.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MatchEventConfig _$MatchEventConfigFromJson(Map json) => MatchEventConfig(
  id: json['id'] as String,
  label: json['label'] as String,
  color: json['color'] as String?,
  isLargerBetter: json['isLargerBetter'] as bool? ?? true,
  docs: json['docs'] as String? ?? '',
  isSensitiveField: json['isSensitiveField'] as bool? ?? true,
);

Map<String, dynamic> _$MatchEventConfigToJson(MatchEventConfig instance) =>
    <String, dynamic>{
      'docs': instance.docs,
      'id': instance.id,
      'label': instance.label,
      'color': instance.color,
      'isLargerBetter': instance.isLargerBetter,
      'isSensitiveField': instance.isSensitiveField,
    };
