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

  /// Used for rainbow table views
  final bool isLargerBetter;

  /// Used to determine if related data should be displayed in kiosk mode
  final bool isSensitiveField;

  const MatchEventConfig({
    required this.id,
    required this.label,
    this.color,
    this.isLargerBetter = true,
    this.docs = '',
    this.isSensitiveField = true,
  });

  factory MatchEventConfig.fromJson(Map<String, dynamic> json) =>
      _$MatchEventConfigFromJson(json);
  Map<String, dynamic> toJson() => _$MatchEventConfigToJson(this);
}
