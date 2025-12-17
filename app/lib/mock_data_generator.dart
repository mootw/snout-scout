import 'dart:math';

import 'package:snout_db/event/frcevent.dart';
import 'package:snout_db/event/match_schedule_item.dart';
import 'package:snout_db/patch.dart';
import 'package:snout_db/snout_db.dart';

const maxFRCTeam = 12000;

List<Patch> generateMockData({
  required int seed,
  int team = 6749,
  int numTeams = 43,
  int numMatches = 86,
}) {
  final random = Random(seed);

  final teams = [for (int i = 0; i < numTeams; i++) random.nextInt(maxFRCTeam)];

  final scouts = [
    "albert",
    "iassac",
    "archimedes",
    "ada",
    "bohr",
    "faraday",
    "galileo",
    "tesla",
  ];

  final startTime = DateTime.now().subtract(Duration(hours: 2));
  final matchInterval = 8;
  final matches = [
    for (int i = 1; i < numMatches; i++)
      MatchScheduleItem(
        id: "qm_$i",
        label: "Quals $i",
        scheduledTime: startTime.add(Duration(minutes: i * matchInterval)),
        blue: [
          teams[random.nextInt(teams.length)],
          teams[random.nextInt(teams.length)],
          teams[random.nextInt(teams.length)],
        ],
        red: [
          teams[random.nextInt(teams.length)],
          teams[random.nextInt(teams.length)],
          teams[random.nextInt(teams.length)],
        ],
      ),
  ];

  Patch initialPatch = Patch(
    identity: '',
    time: startTime,
    path: Patch.buildPath(['']),
    value: FRCEvent(
      config: EventConfig(name: 'Mock $seed', team: team, fieldImage: ''),
    ).toJson(),
  );

  Patch teamsPatch = Patch.teams(startTime, teams);
  Patch schedule = Patch.schedule(startTime, matches);

  return [initialPatch, teamsPatch, schedule];
}
