import 'package:json_annotation/json_annotation.dart';

part 'surveyitem.g.dart';

@JsonSerializable()
class SurveyItem {
  String id;
  String label;
  SurveyItemType type;

  //Used by the selector type
  List<String>? options;
  //TODO automatically calculate scoring and whatnot; maybe an option in the future
  //List<dynamic>? options_values;

  SurveyItem(
      {required this.id,
      required this.type,
      required this.label,
      this.options,
      //this.options_values
      });

  factory SurveyItem.fromJson(Map<String, dynamic> json) =>
      _$SurveyItemFromJson(json);
  Map<String, dynamic> toJson() => _$SurveyItemToJson(this);
}

enum SurveyItemType { selector, picture, toggle, number, text }
