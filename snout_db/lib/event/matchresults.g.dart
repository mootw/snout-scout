// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'matchresults.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MatchResultValues _$MatchResultValuesFromJson(Map json) => MatchResultValues(
      time: DateTime.parse(json['time'] as String),
      redScore: (json['redScore'] as num).toInt(),
      blueScore: (json['blueScore'] as num).toInt(),
    );

Map<String, dynamic> _$MatchResultValuesToJson(MatchResultValues instance) =>
    <String, dynamic>{
      'time': instance.time.toIso8601String(),
      'redScore': instance.redScore,
      'blueScore': instance.blueScore,
    };
