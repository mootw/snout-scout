import 'package:json_annotation/json_annotation.dart';

part 'matchevent_process.g.dart';

/// Schema that defines how data is displayed in the app for match events
@JsonSerializable()
class MatchEventProcess {

  final String label;
  final String expression;

  MatchEventProcess({required this.label, required this.expression});

  
}
