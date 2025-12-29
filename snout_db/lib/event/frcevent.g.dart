// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'frcevent.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FRCEvent _$FRCEventFromJson(Map json) => FRCEvent(
  config: EventConfig.fromJson(
    Map<String, dynamic>.from(json['config'] as Map),
  ),
  matches: (json['matches'] as Map).map(
    (k, e) => MapEntry(k as String, MatchData.fromJson(e as Map)),
  ),
  teams:
      (json['teams'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList() ??
      const [],
  schedule:
      (json['schedule'] as Map?)?.map(
        (k, e) => MapEntry(k as String, MatchScheduleItem.fromJson(e as Map)),
      ) ??
      const {},
);

Map<String, dynamic> _$FRCEventToJson(FRCEvent instance) => <String, dynamic>{
  'config': instance.config.toJson(),
  'teams': instance.teams,
  'schedule': instance.schedule.map((k, e) => MapEntry(k, e.toJson())),
  'matches': instance.matches.map((k, e) => MapEntry(k, e.toJson())),
};
