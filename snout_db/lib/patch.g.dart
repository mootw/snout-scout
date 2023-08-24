// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'patch.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Patch _$PatchFromJson(Map<String, dynamic> json) => Patch(
      identity: json['identity'] as String,
      time: DateTime.parse(json['time'] as String),
      pointer:
          (json['pointer'] as List<dynamic>).map((e) => e as String).toList(),
      data: json['data'] as Object,
    );

Map<String, dynamic> _$PatchToJson(Patch instance) => <String, dynamic>{
      'identity': instance.identity,
      'time': instance.time.toIso8601String(),
      'pointer': instance.pointer,
      'data': instance.data,
    };
