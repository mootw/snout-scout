// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'db.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SnoutDB _$SnoutDBFromJson(Map<String, dynamic> json) => SnoutDB(
      patches: (json['patches'] as List<dynamic>)
          .map((e) => Patch.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$SnoutDBToJson(SnoutDB instance) => <String, dynamic>{
      'patches': instance.patches,
    };
