import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';

part 'data_item_schema.g.dart';

@immutable
@JsonSerializable()
class DataItemSchema {
  /// Documentation about this item
  final String docs;

  /// Must be unique!
  final String id;

  /// Label Displyed in the app
  final String label;

  /// What value type this is
  final DataItemType type;

  /// Used by the selector type to give a list of options
  final List<String>? options;

  /// Used to determine if related data should be displayed in kiosk mode
  final bool isSensitiveField;

  const DataItemSchema({
    required this.id,
    required this.type,
    required this.label,
    this.options,
    this.docs = '',
    this.isSensitiveField = true,
  });

  factory DataItemSchema.fromJson(Map<String, dynamic> json) =>
      _$DataItemSchemaFromJson(json);
  Map<String, dynamic> toJson() => _$DataItemSchemaToJson(this);
}

enum DataItemType { selector, picture, toggle, number, text }
