// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'frcevent.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FRCEvent _$FRCEventFromJson(Map<String, dynamic> json) => FRCEvent(
      name: json['name'] as String,
      teams: (json['teams'] as List<dynamic>).map((e) => e as int).toList(),
      matches: (json['matches'] as List<dynamic>)
          .map((e) => FRCMatch.fromJson(e as Map<String, dynamic>))
          .toList(),
      pitscouting: (json['pitscouting'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(k, e as Map<String, dynamic>),
      ),
    );

Map<String, dynamic> _$FRCEventToJson(FRCEvent instance) => <String, dynamic>{
      'name': instance.name,
      'teams': instance.teams,
      'matches': instance.matches,
      'pitscouting': instance.pitscouting,
    };
