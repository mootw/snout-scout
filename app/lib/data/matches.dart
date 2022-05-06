import 'dart:convert';

List<Match> matchesFromJson(String str) =>
    List<Match>.from(json.decode(str).map((x) => Match.fromJson(x)));

String matchesToJson(List<Match> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class Match {
  Match({
    required this.section,
    required this.number,
    required this.scheduledTime,
    required this.blue,
    required this.red,
    this.results,
  });

  final String section;
  final int number;
  final String scheduledTime;
  final List<int> blue;
  final List<int> red;
  final dynamic results;

  factory Match.fromJson(Map<String, dynamic> json) => Match(
        section: json["section"],
        number: json["number"],
        scheduledTime: json["scheduled_time"],
        blue: List<int>.from(json["blue"].map((x) => x)),
        red: List<int>.from(json["red"].map((x) => x)),
        results: json["results"],
      );

  Map<String, dynamic> toJson() => {
        "section": section,
        "number": number,
        "scheduled_time": scheduledTime,
        "blue": List<dynamic>.from(blue.map((x) => x)),
        "red": List<dynamic>.from(red.map((x) => x)),
        "results": results,
      };
}
