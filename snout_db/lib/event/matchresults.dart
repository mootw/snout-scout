import 'package:json_annotation/json_annotation.dart';
import 'package:snout_db/game.dart';

part 'matchresults.g.dart';

@JsonSerializable()
class MatchResultValues {
  ///the time when the match actually started
  final DateTime time;

  final int redScore;
  final int redRankingPoints;
  final int blueScore;
  final int blueRankingPoints;

  /// 'user-defined' values that pertain to the years specific game
  /// maybe this includes scoring positions, or a specific sub-score category
  /// TODO this is currently unused. eventually write tba data autofill to this?
  final Map<String, dynamic> values;

  const MatchResultValues(
      {required this.time,
      required this.redScore,
      required this.redRankingPoints,
      required this.blueScore,
      required this.blueRankingPoints,
      this.values = const {}});

  factory MatchResultValues.fromJson(Map<String, dynamic> json) =>
      _$MatchResultValuesFromJson(json);
  Map<String, dynamic> toJson() => _$MatchResultValuesToJson(this);

  Alliance get winner {
    if (redScore == blueScore) {
      return Alliance.tie;
    }
    if (redScore > blueScore) {
      return Alliance.red;
    } else {
      return Alliance.blue;
    }
  }
}
