//https://www.thebluealliance.com/apidocs/v3
import 'dart:convert';

import 'package:logging/logging.dart';
import 'package:snout_db/event/frcevent.dart';
import 'package:snout_db/event/match.dart';
import 'package:snout_db/patch.dart';
import 'package:http/http.dart' as http;

final tbaApiClient = http.Client();

Future<({DateTime startTime, int blueScore, int redScore})>
    getMatchResultsDataFromTBA(FRCEvent eventData, String matchID) async {
  if (eventData.config.tbaEventId == null) {
    throw Exception("TBA event ID cannot be null in the config!");
  }
  if (eventData.config.tbaSecretKey == null) {
    throw Exception("tbaSecretKey cannot be null in the config!");
  }

  //Get playoff level matches
  final apiData = await tbaApiClient.get(
      Uri.parse("https://www.thebluealliance.com/api/v3/match/$matchID"),
      headers: {
        'X-TBA-Auth-Key': eventData.config.tbaSecretKey!,
      });

  final data = json.decode(apiData.body);

  return (
    startTime: DateTime.fromMillisecondsSinceEpoch(data['actual_time'] * 1000),
    blueScore: data['alliances']['blue']['score'] as int,
    redScore: data['alliances']['red']['score'] as int,
  );
}

Future<List<int>> getTeamListForEventTBA(FRCEvent eventData) async {
  if (eventData.config.tbaEventId == null) {
    throw Exception("TBA event ID cannot be null in the config!");
  }
  if (eventData.config.tbaSecretKey == null) {
    throw Exception("tbaSecretKey cannot be null in the config!");
  }

  //Get playoff level matches
  final apiData = await tbaApiClient.get(
      Uri.parse(
          "https://www.thebluealliance.com/api/v3/event/${eventData.config.tbaEventId}/teams/simple"),
      headers: {
        'X-TBA-Auth-Key': eventData.config.tbaSecretKey!,
      });

  final teams = json.decode(apiData.body);

  return [
    for (final team in teams) team['team_number'],
  ];
}

Future<List<Patch>> loadScheduleFromTBA(
    FRCEvent eventData, String identity) async {
  if (eventData.config.tbaEventId == null) {
    throw Exception("TBA event ID cannot be null in the config!");
  }
  if (eventData.config.tbaSecretKey == null) {
    throw Exception("tbaSecretKey cannot be null in the config!");
  }

  //Get playoff level matches
  final apiData = await tbaApiClient.get(
      Uri.parse(
          "https://www.thebluealliance.com/api/v3/event/${eventData.config.tbaEventId}/matches"),
      headers: {
        'X-TBA-Auth-Key': eventData.config.tbaSecretKey!,
      });

  //Alright I THINK the timezone for the iso string is the one local to the event, but this would be chaotic
  //(and not to the ISO8601 standard since it should show timezone offset meaning the actual time is WRONG)
  //Basically just place your server in the same timezone as the event and hope for the best lmao

  final matches = json.decode(apiData.body);

  List<Patch> patches = [];

  for (final match in matches) {
    String key = match['key'];
    DateTime startTime =
        DateTime.fromMillisecondsSinceEpoch(match['time'] * 1000, isUtc: true);

    //"red": {
    //   "dq_team_keys": [],
    //   "score": 86,
    //   "surrogate_team_keys": [],
    //   "team_keys": [
    //     "frc2883",
    //     "frc2239",
    //     "frc2129"
    //   ]
    // }
    List<int> red = [
      for (String team in match['alliances']['red']['team_keys'])
        int.parse(team.substring(3)),
    ];
    List<int> blue = [
      for (String team in match['alliances']['blue']['team_keys'])
        int.parse(team.substring(3)),
    ];

    int matchNumber = match['match_number'];
    int setNumber = match['set_number'];
    String compLevel = match['comp_level'];
    //Generate a human readable description for each match
    String description;
    //qm, ef, qf, sf, f
    if (compLevel == "qm") {
      description = "Quals $matchNumber";
    } else if (compLevel == "ef") {
      description = "Eighths $matchNumber Match $setNumber";
    } else if (compLevel == "qf") {
      description = "Quarters $matchNumber Match $setNumber";
    } else if (compLevel == "sf") {
      description = "Semis $matchNumber Match $setNumber";
    } else if (compLevel == "f") {
      description = "Finals $matchNumber";
    } else {
      description = "Unknown $matchNumber";
    }

    //ONLY modify matches that do not exist yet to prevent damage
    if (eventData.matches.keys.toList().contains(key) == false) {
      Logger.root.info("match $key does not exist; adding...");
      FRCMatch newMatch = FRCMatch(
          description: description,
          scheduledTime: startTime,
          blue: blue,
          red: red,
          results: null,
          robot: const {});

      Patch patch = Patch(
          identity: 'schedule autofill - $identity',
          time: DateTime.now(),
          path: Patch.buildPath([
            'matches',
            key,
          ]),
          value: newMatch.toJson());

      patches.add(patch);
    }
  }
  return patches;
}
