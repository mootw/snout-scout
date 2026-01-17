import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cbor/cbor.dart';
import 'package:cryptography/cryptography.dart';
import 'package:snout_db/action.dart';
import 'package:snout_db/actions/add_keypair.dart';
import 'package:snout_db/actions/write_config.dart';
import 'package:snout_db/actions/write_dataitem.dart';
import 'package:snout_db/actions/write_matchresults.dart';
import 'package:snout_db/actions/write_matchtrace.dart';
import 'package:snout_db/actions/write_schedule.dart';
import 'package:snout_db/actions/write_teams.dart';
import 'package:snout_db/data_item.dart';
import 'package:snout_db/event/match_schedule_item.dart';
import 'package:snout_db/event/matchresults.dart';
import 'package:snout_db/event/robot_match_trace.dart';
import 'package:snout_db/match_result.dart';
import 'package:snout_db/match_trace.dart';
import 'package:snout_db/pubkey.dart';
import 'package:snout_db/snout_chain.dart';
import 'package:snout_db/crypto.dart';
import 'package:snout_db_legacy/db.dart' as legacy;
import 'package:snout_db_legacy/config/eventconfig.dart' as legacyevent;

void main(List<String> args) async {
  if (args.isEmpty) {
    print('Usage: dart bin/convert.dart <path/to/file.snoutdb>');
    exit(1);
  }

  final filePath = args[0];
  final file = File(filePath);

  if (!file.existsSync()) {
    print('File not found: $filePath');
    exit(1);
  }

  try {
    final str = file.readAsStringSync();

    final db = legacy.SnoutDB.fromJson(
      json.decode(str) as Map<String, dynamic>,
    );

    print('original patch count: ${db.patches.length}');

    List<ChainAction> actions = [];

    final configJson = db.event.config.toJson();
    if (configJson['matchscouting'] != null &&
        configJson['matchscouting']['processes'] != null) {
      for (final process in configJson['matchscouting']['processes']) {
        String expression = process['expression'];
        expression = expression.replaceAll('PITSCOUTINGIS', 'TEAMDATAIS');
        expression = expression.replaceAll('POSTGAMEIS', 'MATCHTEAMIS');

        expression = expression.replaceAll(
          'AUTOEVENTINBBOX(',
          'PEVENTINBBOX("auto", ',
        );
        expression = expression.replaceAll(
          'TELEOPEVENTINBBOX(',
          'PEVENTINBBOX("teleop", ',
        );

        expression = expression.replaceAll('AUTOEVENT(', 'PEVENT("auto", ');
        expression = expression.replaceAll('TELEOPEVENT(', 'PEVENT("teleop", ');

        process['expression'] = expression;
      }
    }

    actions.add(
      // Handle the type change to the new format since they are identical schemas
      ActionWriteConfig(EventConfig.fromJson(configJson)),
    );

    actions.add(ActionWriteTeams(db.event.teams));

    final pitmap = db.event.pitmap;
    if (pitmap != null) {
      actions.add(
        ActionWriteDataItem(
          DataItem.pit('pit_map', CborBytes(base64Decode(pitmap))),
        ),
      );
      actions.add(
        ActionWriteDataItem(
          DataItem.pit(
            'docs',
            legacyevent.EventConfig.fromJson(db.event.config.toJson()).docs,
          ),
        ),
      );
    }

    actions.add(
      ActionWriteSchedule([
        for (final scheduleItem in db.event.schedule.entries)
          // Handle type mismatch
          MatchScheduleItem.fromJson(scheduleItem.value.toJson()),
      ]),
    );

    for (final match in db.event.matches.entries) {
      for (final team in match.value.robot.entries) {
        final traceData = team.value.toJson();
        for (final event in traceData['timeline']) {
          event['timeMS'] = (event['time'] * 1000).toInt();
        }

        final matchTrace = MatchTrace(
          match: match.key,
          team: int.parse(team.key),
          // Handle type mismatch
          trace: RobotMatchTraceData.fromJson(traceData),
        );

        final action = ActionWriteMatchTrace(matchTrace);
        actions.add(action);

        for (final item in team.value.survey.entries) {
          final itemValue = item.value;
          final dataItem = DataItem.matchTeam(
            match.key,
            int.parse(team.key),
            item.key,
            itemValue is String && itemValue.length > 9999
                ? CborBytes(base64Decode(itemValue))
                : itemValue,
          );
          final action = ActionWriteDataItem(dataItem);
          actions.add(action);
        }
      }
    }

    for (final team in db.event.pitscouting.entries) {
      for (final item in team.value.entries) {
        // TODO encode the data item values correctly lol
        final itemValue = item.value;

        final dataItem = DataItem.team(
          int.parse(team.key),
          item.key,
          // Assume long strings are binary data (aka pictures encoded as base64)
          // All numbers should be floats (no ints)
          itemValue is String && itemValue.length > 9999
              ? CborBytes(base64Decode(itemValue))
              : itemValue,
        );
        final action = ActionWriteDataItem(dataItem);
        actions.add(action);
      }
    }

    for (final match in db.event.matches.entries) {
      if (match.value.results != null) {
        final action = ActionWriteMatchResults(
          MatchResult(
            match: match.key,
            result: MatchResultValues(
              blueScore: match.value.results!.blueScore,
              redScore: match.value.results!.redScore,
              time: match.value.results!.time,
            ),
          ),
        );
        actions.add(action);
      }
    }

    print(actions.length);

    final seed = Uint8List(32);

    final keyPair = await Ed25519().newKeyPairFromSeed(seed);

    var lastHash = List<int>.filled(32, 0);

    final snoutChain = SnoutChain([
      await ChainActionData(
        time: DateTime.now(),
        previousHash: lastHash,
        action: ActionWriteKeyPair(
          await encryptSeedKey(seedKey: seed, password: utf8.encode('1234')),
          await keyPair.extractPublicKey().then((value) => Pubkey(value.bytes)),
          'db-conversion-tool',
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

    print('signed password 1234');

    final outFile = File('$filePath.converted.snoutdb');
    outFile.writeAsBytesSync(
      cbor.encode(SnoutDBFile(actions: snoutChain.actions).toCbor()),
    );

    print('loading');

    final loadedDb = SnoutDBFile.fromCbor(
      cbor.decode(outFile.readAsBytesSync()) as CborMap,
    );

    print('loaded ${loadedDb.actions.length} actions');

    final chain = SnoutChain(loadedDb.actions);

    print(chain.event.dataItems.keys);
  } catch (e, s) {
    print('Error reading file: $e $s');
    exit(1);
  }
}
