import 'package:json_annotation/json_annotation.dart';

part 'match_period_config.g.dart';

const String autoPeriodId = 'auto';
const String teleopPeriodId = 'teleop';

/// 0.0 seconds is reserved for events before the match starts like starting pos
/// for scoring and scouting UI purposes. It is better that the scout records
/// an auto event outside of auto than to miss the transition messing up the
/// entire match recording.
///
/// NOTE when setting periods, include disabled time between two periods in the
/// duration of the earlier period. For example: if auto ends at 15s and
/// there is 2 seconds of disabled time, set auto period to 17s.
@JsonSerializable()
class MatchPeriodConfig {
  final String id;
  final String label;

  // How long this period is in DURATION in seconds.
  final int durationSeconds;

  const MatchPeriodConfig({
    required this.id,
    required this.label,
    required this.durationSeconds,
  });

  factory MatchPeriodConfig.fromJson(Map<String, dynamic> json) =>
      _$MatchPeriodConfigFromJson(json);

  Map<String, dynamic> toJson() => _$MatchPeriodConfigToJson(this);
}
