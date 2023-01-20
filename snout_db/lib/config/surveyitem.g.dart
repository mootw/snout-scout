// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'surveyitem.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SurveyItem _$SurveyItemFromJson(Map<String, dynamic> json) => SurveyItem(
      id: json['id'] as String,
      type: $enumDecode(_$SurveyItemTypeEnumMap, json['type']),
      label: json['label'] as String,
      options:
          (json['options'] as List<dynamic>?)?.map((e) => e as String).toList(),
      options_values: json['options_values'] as List<dynamic>?,
    );

Map<String, dynamic> _$SurveyItemToJson(SurveyItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'label': instance.label,
      'type': _$SurveyItemTypeEnumMap[instance.type]!,
      'options': instance.options,
      'options_values': instance.options_values,
    };

const _$SurveyItemTypeEnumMap = {
  SurveyItemType.selector: 'selector',
  SurveyItemType.picture: 'picture',
  SurveyItemType.toggle: 'toggle',
  SurveyItemType.number: 'number',
  SurveyItemType.text: 'text',
};