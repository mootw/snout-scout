// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'patch.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Patch _$PatchFromJson(Map json) => Patch(
      identity: json['identity'] as String,
      time: DateTime.parse(json['time'] as String),
      path: (json['path'] as List<dynamic>).map((e) => e as String).toList(),
      value: json['value'] as Object,
    );

Map<String, dynamic> _$PatchToJson(Patch instance) => <String, dynamic>{
      'identity': instance.identity,
      'time': instance.time.toIso8601String(),
      'path': instance.path,
      'value': instance.value,
    };
