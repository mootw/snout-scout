import 'package:json_annotation/json_annotation.dart';

part 'matcheventconfig.g.dart';

/// Template for a match event that could be recorded
@JsonSerializable()
class MatchEventConfig {

  final String id;
  final String label;
  final String? color;

  const MatchEventConfig({
    required this.id,
    required this.label,
    this.color,
  });

  factory MatchEventConfig.fromJson(Map<String, dynamic> json) =>
      _$MatchEventConfigFromJson(json);
  Map<String, dynamic> toJson() => _$MatchEventConfigToJson(this);
}
