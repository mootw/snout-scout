// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'data_item_schema.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DataItemSchema _$DataItemSchemaFromJson(Map json) => DataItemSchema(
  id: json['id'] as String,
  type: $enumDecode(_$DataItemTypeEnumMap, json['type']),
  label: json['label'] as String,
  options: (json['options'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  docs: json['docs'] as String? ?? '',
  isSensitiveField: json['isSensitiveField'] as bool? ?? true,
);

Map<String, dynamic> _$DataItemSchemaToJson(DataItemSchema instance) =>
    <String, dynamic>{
      'docs': instance.docs,
      'id': instance.id,
      'label': instance.label,
      'type': _$DataItemTypeEnumMap[instance.type]!,
      'options': instance.options,
      'isSensitiveField': instance.isSensitiveField,
    };

const _$DataItemTypeEnumMap = {
  DataItemType.selector: 'selector',
  DataItemType.picture: 'picture',
  DataItemType.toggle: 'toggle',
  DataItemType.number: 'number',
  DataItemType.text: 'text',
};
