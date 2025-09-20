// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'db.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SnoutDB _$SnoutDBFromJson(Map json) => SnoutDB(
  patches:
      (json['patches'] as List<dynamic>)
          .map((e) => Patch.fromJson(e as Map))
          .toList(),
);

Map<String, dynamic> _$SnoutDBToJson(SnoutDB instance) => <String, dynamic>{
  'event': instance.event.toJson(),
  'patches': instance.patches.map((e) => e.toJson()).toList(),
};
