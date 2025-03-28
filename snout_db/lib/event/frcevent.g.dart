// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'frcevent.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FRCEvent _$FRCEventFromJson(Map json) => FRCEvent(
      config: EventConfig.fromJson(
          Map<String, dynamic>.from(json['config'] as Map)),
      teams: (json['teams'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const [],
      schedule: json['schedule'] as List<dynamic>? ?? const [],
      matches: (json['matches'] as Map?)?.map(
            (k, e) => MapEntry(k as String, FRCMatch.fromJson(e as Map)),
          ) ??
          const {},
      pitscouting: (json['pitscouting'] as Map?)?.map(
            (k, e) =>
                MapEntry(k as String, Map<String, dynamic>.from(e as Map)),
          ) ??
          const {},
      scoutPasswords: (json['scoutPasswords'] as Map?)?.map(
            (k, e) => MapEntry(k as String, e as String),
          ) ??
          const {},
      pitmap: json['pitmap'] as String?,
    );

Map<String, dynamic> _$FRCEventToJson(FRCEvent instance) => <String, dynamic>{
      'config': instance.config.toJson(),
      'teams': instance.teams,
      'schedule': instance.schedule,
      'matches': instance.matches.map((k, e) => MapEntry(k, e.toJson())),
      'pitscouting': instance.pitscouting,
      'pitmap': instance.pitmap,
      'scoutPasswords': instance.scoutPasswords,
    };
