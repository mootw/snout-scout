import 'package:json_annotation/json_annotation.dart';
import 'package:snout_db/game.dart';

part 'matchresults.g.dart';

@JsonSerializable()
class MatchResults {
  
  final DateTime time;
  final Map<String, int> red;
  final Map<String, int> blue;

  MatchResults({required this.time, required this.red,
  required this.blue});

  factory MatchResults.fromJson(Map<String, dynamic> json) => _$MatchResultsFromJson(json);
  Map<String, dynamic> toJson() => _$MatchResultsToJson(this);

  Alliance get winner {
    int redPts = red['points']!;
    int bluePts = blue['points']!;
    if(redPts == bluePts) {
      return Alliance.tie;
    }
    if(redPts > bluePts) {
      return Alliance.red;
    } else {
      return Alliance.blue;
    }
  }
}


