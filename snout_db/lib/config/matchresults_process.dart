import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
part 'matchresults_process.g.dart';

/// Schema that defines how data is displayed in the app for match events
@immutable
@JsonSerializable()
class MatchResultsProcess {
  /// documentation about this item
  final String docs;

  /// unique
  final String id;
  final String label;
  final String expression;

  const MatchResultsProcess(
      {required this.id,
      required this.label,
      required this.expression,
      this.docs = '',});

  factory MatchResultsProcess.fromJson(Map<String, dynamic> json) =>
      _$MatchResultsProcessFromJson(json);
  Map<String, dynamic> toJson() => _$MatchResultsProcessToJson(this);
}
