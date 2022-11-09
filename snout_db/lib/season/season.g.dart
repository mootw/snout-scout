// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'season.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Season _$SeasonFromJson(Map<String, dynamic> json) => Season(
      team: json['team'] as int,
      season: json['season'] as String,
      pitscouting: (json['pitscouting'] as List<dynamic>)
          .map((e) => SurveyItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      matchscouting:
          MatchScouting.fromJson(json['matchscouting'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$SeasonToJson(Season instance) => <String, dynamic>{
      'season': instance.season,
      'team': instance.team,
      'pitscouting': instance.pitscouting,
      'matchscouting': instance.matchscouting,
    };
