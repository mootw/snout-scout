import 'dart:convert';

SeasonConfig seasonConfigFromJson(String str) =>
    SeasonConfig.fromJson(json.decode(str));

String seasonConfigToJson(SeasonConfig data) => json.encode(data.toJson());

class SeasonConfig {
  SeasonConfig({
    required this.pitScouting,
    required this.matchScouting,
    required this.season,
  });

  final PitScouting pitScouting;
  final MatchScouting matchScouting;
  final String season;

  factory SeasonConfig.fromJson(Map<String, dynamic> json) => SeasonConfig(
        pitScouting: PitScouting.fromJson(json["pit_scouting"]),
        matchScouting: MatchScouting.fromJson(json["match_scouting"]),
        season: json["season"],
      );

  Map<String, dynamic> toJson() => {
        "pit_scouting": pitScouting.toJson(),
        "match_scouting": matchScouting.toJson(),
        "season": season,
      };
}

class PitScouting {
  PitScouting({
    required this.survey,
  });

  final List<ScoutingToolData> survey;

  factory PitScouting.fromJson(Map<String, dynamic> json) => PitScouting(
        survey: List<ScoutingToolData>.from(
            json["survey"].map((x) => ScoutingToolData.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "survey": List<dynamic>.from(survey.map((x) => x.toJson())),
      };
}

class MatchScouting {
  MatchScouting({
    required this.pregame,
    required this.auto,
    required this.teleop,
    required this.endgame,
    required this.postgame,
    required this.results,
  });

  final List<ScoutingToolData> pregame;
  final List<ScoutingToolData> auto;
  final List<ScoutingToolData> teleop;
  final List<ScoutingToolData> endgame;
  final List<ScoutingToolData> postgame;
  final List<String> results;

  factory MatchScouting.fromJson(Map<String, dynamic> json) => MatchScouting(
        pregame: List<ScoutingToolData>.from(
            json["pregame"].map((x) => ScoutingToolData.fromJson(x))),
        auto: List<ScoutingToolData>.from(
            json["auto"].map((x) => ScoutingToolData.fromJson(x))),
        teleop: List<ScoutingToolData>.from(
            json["teleop"].map((x) => ScoutingToolData.fromJson(x))),
        endgame: List<ScoutingToolData>.from(
            json["endgame"].map((x) => ScoutingToolData.fromJson(x))),
        postgame: List<ScoutingToolData>.from(
            json["postgame"].map((x) => ScoutingToolData.fromJson(x))),
        results: List<String>.from(json["results"].map((x) => x)),
      );

  Map<String, dynamic> toJson() => {
        "pregame": List<dynamic>.from(pregame.map((x) => x.toJson())),
        "auto": List<dynamic>.from(auto.map((x) => x.toJson())),
        "teleop": List<dynamic>.from(teleop.map((x) => x.toJson())),
        "endgame": List<dynamic>.from(endgame.map((x) => x.toJson())),
        "postgame": List<dynamic>.from(postgame.map((x) => x.toJson())),
        "results": List<dynamic>.from(results.map((x) => x)),
      };
}

class ScoutingToolData {
  late final Map<String, dynamic> values;

  ScoutingToolData({required this.values});

  ScoutingToolData.fromPosition (x, y) {
    values = {
      "type": "robot_position",
      "label": "Robot Position",
      "x": x,
      "y": y,
    };
  }

  factory ScoutingToolData.fromJson(Map<String, dynamic> json) =>
      ScoutingToolData(
        values: json,
      );

  Map<String, dynamic> toJson() => values;

  get id {
    return values['id'];
  }

  get type {
    return values['type'];
  }

  get label {
    return values['label'];
  }


  get options {
    return List<String>.from(values["options"].map((x) => x));
  }

  double getNumber(String key) {
    return values[key].toDouble();
  }
}
