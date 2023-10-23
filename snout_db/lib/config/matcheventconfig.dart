import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';

part 'matcheventconfig.g.dart';

/// Template for a match event that could be recorded
@immutable
@JsonSerializable()
class MatchEventConfig {
  /// documentation about this item
  final String docs;

  /// unique
  final String id;

  final String label;

  /// #HEX color that identifies this event
  /// the background of event buttons in match recorder
  final String? color;

  const MatchEventConfig({
    required this.id,
    required this.label,
    this.color,
    this.docs = '',
  });

  factory MatchEventConfig.fromJson(Map<String, dynamic> json) =>
      _$MatchEventConfigFromJson(json);
  Map<String, dynamic> toJson() => _$MatchEventConfigToJson(this);
}
