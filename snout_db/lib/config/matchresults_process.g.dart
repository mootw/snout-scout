// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'matchresults_process.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MatchResultsProcess _$MatchResultsProcessFromJson(Map json) =>
    MatchResultsProcess(
      id: json['id'] as String,
      label: json['label'] as String,
      expression: json['expression'] as String,
      isLargerBetter: json['isLargerBetter'] as bool? ?? true,
      docs: json['docs'] as String? ?? '',
    );

Map<String, dynamic> _$MatchResultsProcessToJson(
  MatchResultsProcess instance,
) => <String, dynamic>{
  'docs': instance.docs,
  'id': instance.id,
  'label': instance.label,
  'expression': instance.expression,
  'isLargerBetter': instance.isLargerBetter,
};
