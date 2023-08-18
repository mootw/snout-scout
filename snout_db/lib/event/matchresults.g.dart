// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'matchresults.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MatchResultValues _$MatchResultValuesFromJson(Map<String, dynamic> json) =>
    MatchResultValues(
      time: DateTime.parse(json['time'] as String),
      redScore: json['redScore'] as int,
      redRankingPoints: json['redRankingPoints'] as int,
      blueScore: json['blueScore'] as int,
      blueRankingPoints: json['blueRankingPoints'] as int,
      values: json['values'] as Map<String, dynamic>? ?? const {},
    );

Map<String, dynamic> _$MatchResultValuesToJson(MatchResultValues instance) =>
    <String, dynamic>{
      'time': instance.time.toIso8601String(),
      'redScore': instance.redScore,
      'redRankingPoints': instance.redRankingPoints,
      'blueScore': instance.blueScore,
      'blueRankingPoints': instance.blueRankingPoints,
      'values': instance.values,
    };
