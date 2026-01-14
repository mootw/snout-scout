// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'match_period_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MatchPeriodConfig _$MatchPeriodConfigFromJson(Map json) => MatchPeriodConfig(
  id: json['id'] as String,
  label: json['label'] as String,
  durationSeconds: (json['durationSeconds'] as num).toInt(),
);

Map<String, dynamic> _$MatchPeriodConfigToJson(MatchPeriodConfig instance) =>
    <String, dynamic>{
      'id': instance.id,
      'label': instance.label,
      'durationSeconds': instance.durationSeconds,
    };
