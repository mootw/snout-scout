// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'patch.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Patch _$PatchFromJson(Map<String, dynamic> json) => Patch(
      user: json['user'] as String,
      time: DateTime.parse(json['time'] as String),
      path: (json['path'] as List<dynamic>).map((e) => e as String).toList(),
      data: json['data'] as String,
    );

Map<String, dynamic> _$PatchToJson(Patch instance) => <String, dynamic>{
      'user': instance.user,
      'time': instance.time.toIso8601String(),
      'path': instance.path,
      'data': instance.data,
    };
