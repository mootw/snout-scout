import 'dart:convert';

import 'package:app/data/match_results.dart';
import 'package:app/data/timeline_event.dart';
import 'package:app/screens/match_recorder.dart';

List<Match> matchesFromJson(String str) =>
    List<Match>.from(json.decode(str).map((x) => Match.fromJson(x)));

String matchesToJson(List<Match> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class Match {
  Match({
    required this.id,
    required this.section,
    required this.number,
    required this.scheduledTime,
    required this.blue,
    required this.red,
    this.results,
    required this.timelines,
  });

  final String id;
  final String section;
  final int number;
  final String scheduledTime;
  final List<int> blue;
  final List<int> red;
  final MatchResults? results;
  final Map<String, List<TimelineEvent>> timelines;

  factory Match.fromJson(Map<String, dynamic> json) => Match(
        id: json['id'],
        section: json["section"],
        number: json["number"],
        scheduledTime: json["scheduled_time"],
        blue: List<int>.from(json["blue"].map((x) => x)),
        red: List<int>.from(json["red"].map((x) => x)),
        results: json["results"] == null
            ? null
            : MatchResults.fromJson(json["results"]),
        timelines: json["timelines"].map((e,s) => MapEntry(e, 
         []
         // List<TimelineEvent>.from(s.map((x) => TimelineEvent.fromJson(s)))
        )),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "section": section,
        "number": number,
        "scheduled_time": scheduledTime,
        "blue": List<dynamic>.from(blue.map((x) => x)),
        "red": List<dynamic>.from(red.map((x) => x)),
        "results": results?.toJson(),
      };
}
