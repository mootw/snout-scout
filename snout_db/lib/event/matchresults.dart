import 'package:json_annotation/json_annotation.dart';

part 'matchresults.g.dart';

@JsonSerializable()
class MatchResults {
  
  DateTime time;
  Map<String, int> red;
  Map<String, int> blue;

  MatchResults({required this.time, required this.red,
  required this.blue});

  factory MatchResults.fromJson(Map<String, dynamic> json) => _$MatchResultsFromJson(json);
  Map<String, dynamic> toJson() => _$MatchResultsToJson(this);

  get winner {
    int redPts = red['points']!;
    int bluePts = blue['points']!;
    if(redPts == bluePts) {
      return "tie";
    }
    if(redPts > bluePts) {
      return "red";
    } else {
      return "blue";
    }
  }
}


enum TournamentLevel { None, Practice, Qualification, Playoff }