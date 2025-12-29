import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
part 'matchresults_process.g.dart';

/// Schema that defines how data is displayed in the app for match events
@immutable
@JsonSerializable()
class MatchResultsProcess {
  /// documentation about this item
  final String docs;

  /// Must be unique
  final String id;

  /// Displayed in the app for this process
  final String label;

  /// Calculation to determine the value from this process
  final String expression;

  /// Used for rainbow table views
  final bool isLargerBetter;

  /// Used to determine if related data should be displayed in kiosk mode
  final bool isSensitiveField;

  const MatchResultsProcess({
    required this.id,
    required this.label,
    required this.expression,
    this.isLargerBetter = true,
    this.docs = '',
    this.isSensitiveField = true,
  });

  factory MatchResultsProcess.fromJson(Map<String, dynamic> json) =>
      _$MatchResultsProcessFromJson(json);
  Map<String, dynamic> toJson() => _$MatchResultsProcessToJson(this);
}
