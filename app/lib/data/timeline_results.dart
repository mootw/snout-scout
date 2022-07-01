// To parse this JSON data, do
//
//     final timelineResults = timelineResultsFromJson(jsonString);

import 'dart:convert';

import 'package:app/data/timeline_event.dart';

TimelineResults timelineResultsFromJson(String str) => TimelineResults.fromJson(json.decode(str));

String timelineResultsToJson(TimelineResults data) => json.encode(data.toJson());

class TimelineResults {
    TimelineResults({
        required this.scout,
        required this.time,
        required this.events,
    });

    final String scout;
    final String time;
    final List<TimelineEvent> events;

    factory TimelineResults.fromJson(Map<String, dynamic> json) => TimelineResults(
        scout: json["scout"],
        time: json["time"],
        events: List<TimelineEvent>.from(json["events"].map((x) => TimelineEvent.fromJson(x))),
    );

    Map<String, dynamic> toJson() => {
        "scout": scout,
        "time": time,
        "events": List<dynamic>.from(events.map((x) => x.toJson())),
    };
}