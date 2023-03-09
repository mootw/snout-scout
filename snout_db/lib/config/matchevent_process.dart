import 'package:json_annotation/json_annotation.dart';
part 'matchevent_process.g.dart';

/// Schema that defines how data is displayed in the app for match events
@JsonSerializable()
class MatchEventProcess {
  final String id;
  final String label;
  final String expression;

  MatchEventProcess(
      {required this.id, required this.label, required this.expression});

  factory MatchEventProcess.fromJson(Map<String, dynamic> json) =>
      _$MatchEventProcessFromJson(json);
  Map<String, dynamic> toJson() => _$MatchEventProcessToJson(this);

}
