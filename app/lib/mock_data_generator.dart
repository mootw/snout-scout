import 'dart:math';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:cryptography/cryptography.dart';
import 'package:snout_db/action.dart';
import 'package:snout_db/actions/add_keypair.dart';
import 'package:snout_db/actions/write_config.dart';
import 'package:snout_db/actions/write_schedule.dart';
import 'package:snout_db/actions/write_teams.dart';
import 'package:snout_db/crypto.dart';
import 'package:snout_db/event/match_schedule_item.dart';
import 'package:snout_db/message.dart';
import 'package:snout_db/pubkey.dart';
import 'package:snout_db/snout_chain.dart';

const maxFRCTeam = 12000;

Future<List<SignedChainMessage>> generateMockData({
  required int seed,
  int team = 6749,
  int numTeams = 43,
  int numMatches = 86,
}) async {
  final random = Random(seed);

  final teams = [
    for (int i = 0; i < numTeams; i++) random.nextInt(maxFRCTeam),
  ].sorted((a, b) => a.compareTo(b));

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

  final config = ActionWriteConfig(
    EventConfig(name: 'Mock $seed', team: team, fieldImage: ''),
  );

  final teamsPatch = ActionWriteTeams(teams);
  final schedule = ActionWriteSchedule(matches);

  return await _signActions([config, teamsPatch, schedule]);
}

Future<List<SignedChainMessage>> _signActions(List<ChainAction> actions) async {
  final seed = Uint8List(32);

  final keyPair = await Ed25519().newKeyPairFromSeed(seed);

  var lastHash = List<int>.filled(32, 0);

  final snoutChain = SnoutChain([
    await ChainActionData(
      time: DateTime.now(),
      previousHash: lastHash,
      action: ActionWriteKeyPair(
        await encryptSeedKey(seedKey: seed, password: [1, 2, 3]),
        await keyPair.extractPublicKey().then((value) => Pubkey(value.bytes)),
        'demo data',
      ),
    ).encodeAndSign(seed),
  ]);
  lastHash = await snoutChain.actions.first.hash;
  for (final action in actions) {
    final chainAction = ChainActionData(
      time: DateTime.now(),
      previousHash: lastHash,
      action: action,
    );
    final signedMessage = await chainAction.encodeAndSign(seed);
    await snoutChain.verifyApplyAction(signedMessage);
    lastHash = await signedMessage.hash;
  }
  return snoutChain.actions;
}
