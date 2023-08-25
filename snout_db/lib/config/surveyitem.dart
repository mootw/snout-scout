import 'package:json_annotation/json_annotation.dart';

part 'surveyitem.g.dart';

@JsonSerializable()
class SurveyItem {
  /// documentation about this item
  final String docs;

  /// unique
  final String id;
  final String label;
  final SurveyItemType type;

  //Used by the selector type
  final List<String>? options;
  //List<dynamic>? options_values;

  const SurveyItem(
      {required this.id,
      required this.type,
      required this.label,
      this.options,
      this.docs = ''});

  factory SurveyItem.fromJson(Map<String, dynamic> json) =>
      _$SurveyItemFromJson(json);
  Map<String, dynamic> toJson() => _$SurveyItemToJson(this);
}

enum SurveyItemType { selector, picture, toggle, number, text }
