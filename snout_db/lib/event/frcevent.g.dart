// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'frcevent.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FRCEvent _$FRCEventFromJson(Map<String, dynamic> json) => FRCEvent(
      config: EventConfig.fromJson(json['config'] as Map<String, dynamic>),
      teams: (json['teams'] as List<dynamic>).map((e) => e as int).toList(),
      matches: (json['matches'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(k, FRCMatch.fromJson(e as Map<String, dynamic>)),
      ),
      pitscouting: (json['pitscouting'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(k, e as Map<String, dynamic>),
      ),
    );

Map<String, dynamic> _$FRCEventToJson(FRCEvent instance) => <String, dynamic>{
      'teams': instance.teams,
      'config': instance.config,
      'matches': instance.matches,
      'pitscouting': instance.pitscouting,
    };
