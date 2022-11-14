import 'package:json_annotation/json_annotation.dart';

part 'matcheventconfig.g.dart';

/// Template for a match event that could be recorded
@JsonSerializable()
class MatchEventConfig {
  
  String id;
  String label;
  MatchSegment mode;

  MatchEventConfig(
      //Default match event time to zero to allow for defining an event in the season config
      //without a time, since that wouldn't make sense.
      {
      required this.id,
      required this.mode,
      required this.label,
      });

  factory MatchEventConfig.fromJson(Map<String, dynamic> json) =>
      _$MatchEventConfigFromJson(json);
  Map<String, dynamic> toJson() => _$MatchEventConfigToJson(this);

}

enum MatchSegment {auto, teleop, both}
