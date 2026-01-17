import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';

part 'surveyitem.g.dart';

@immutable
@JsonSerializable()
class SurveyItem {
  /// Documentation about this item
  final String docs;

  /// Must be unique
  final String id;

  /// Displyed in the app
  final String label;

  /// What value type this is
  final SurveyItemType type;

  /// Used by the selector type to give a list of options
  final List<String>? options;

  /// Used to determine if related data should be displayed in kiosk mode
  final bool isSensitiveField;

  const SurveyItem({
    required this.id,
    required this.type,
    required this.label,
    this.options,
    this.docs = '',
    this.isSensitiveField = true,
  });

  factory SurveyItem.fromJson(Map<String, dynamic> json) =>
      _$SurveyItemFromJson(json);
  Map<String, dynamic> toJson() => _$SurveyItemToJson(this);
}

enum SurveyItemType { selector, picture, toggle, number, text }
