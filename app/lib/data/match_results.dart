// To parse this JSON data, do
//
//     final matchResults = matchResultsFromJson(jsonString);

import 'dart:convert';

MatchResults matchResultsFromJson(String str) => MatchResults.fromJson(json.decode(str));

String matchResultsToJson(MatchResults data) => json.encode(data.toJson());

class MatchResults {
    MatchResults({
        required this.scout,
        required this.time,
        required this.startTime,
        required this.red,
        required this.blue,
    });

    String scout;
    String time;
    String startTime;
    ResultsNumbers red;
    ResultsNumbers blue;

    factory MatchResults.fromJson(Map<String, dynamic> json) => MatchResults(
        scout: json["scout"],
        time: json["time"],
        startTime: json["start_time"],
        red: ResultsNumbers.fromJson(json["red"]),
        blue: ResultsNumbers.fromJson(json["blue"]),
    );

    Map<String, dynamic> toJson() => {
        "scout": scout,
        "time": time,
        "start_time": startTime,
        "red": red.toJson(),
        "blue": blue.toJson(),
    };
}



class ResultsNumbers {
   
  final Map<String, dynamic> values;

  ResultsNumbers({required this.values});

  factory ResultsNumbers.fromJson(Map<String, dynamic> json) =>
      ResultsNumbers(
        values: json,
      );

  Map<String, dynamic> toJson() => values;
}
