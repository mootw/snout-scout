import 'package:json_annotation/json_annotation.dart';

part 'pitsurveyitem.g.dart';

@JsonSerializable()
class PitSurveyItem {

  String id;
  String label;
  String type;

  //Used by the selector type
  List<String>? options;
  List<dynamic>? options_values;

  PitSurveyItem({required this.id, required this.type, required this.label ,this.options, this.options_values});

  factory PitSurveyItem.fromJson(Map<String, dynamic> json) => _$PitSurveyItemFromJson(json);
  Map<String, dynamic> toJson() => _$PitSurveyItemToJson(this);
}