// To parse this JSON data, do
//
//     final scoutingResults = scoutingResultsFromJson(jsonString);

import 'dart:convert';

ScoutingResults scoutingResultsFromJson(String str) =>
    ScoutingResults.fromJson(json.decode(str));

String scoutingResultsToJson(ScoutingResults data) =>
    json.encode(data.toJson());

class ScoutingResults {
  ScoutingResults({
    required this.team,
    required this.time,
    required this.scout,
    required this.survey,
  });

  int team;
  String time;
  String scout;
  List<Survey> survey;

  factory ScoutingResults.fromJson(Map<String, dynamic> json) =>
      ScoutingResults(
        team: json["team"],
        time: json["time"],
        scout: json["scout"],
        survey:
            List<Survey>.from(json["survey"].map((x) => Survey.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "team": team,
        "time": time,
        "scout": scout,
        "survey": List<dynamic>.from(survey.map((x) => x.toJson())),
      };
}

class Survey {
  Survey({
    required this.id,
    required this.type,
    required this.value,
  });

  String id;
  String type;
  dynamic value;

  factory Survey.fromJson(Map<String, dynamic> json) => Survey(
        id: json["id"],
        type: json["type"],
        value: json["value"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "type": type,
        "value": value,
      };
}
