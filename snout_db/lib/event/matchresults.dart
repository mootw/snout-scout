import 'package:json_annotation/json_annotation.dart';
import 'package:snout_db/game.dart';

part 'matchresults.g.dart';

@JsonSerializable()
class MatchResultValues {
  ///the time when the match actually started
  final DateTime time;

  final int redScore;
  final int blueScore;

  const MatchResultValues(
      {required this.time,
      required this.redScore,
      required this.blueScore});

  factory MatchResultValues.fromJson(Map json) =>
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
