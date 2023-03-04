import 'package:json_annotation/json_annotation.dart';

part 'matcheventconfig.g.dart';

/// Template for a match event that could be recorded
@JsonSerializable()
class MatchEventConfig {

  String id;
  String label;
  MatchSegment mode;
  String? color;

  MatchEventConfig({
    required this.id,
    required this.mode,
    required this.label,
    this.color,
  });

  factory MatchEventConfig.fromJson(Map<String, dynamic> json) =>
      _$MatchEventConfigFromJson(json);
  Map<String, dynamic> toJson() => _$MatchEventConfigToJson(this);
}

enum MatchSegment { auto, teleop, both }
