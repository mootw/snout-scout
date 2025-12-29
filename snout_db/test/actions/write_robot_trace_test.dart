import 'dart:convert';
import 'dart:io';

import 'package:snout_db/action.dart';
import 'package:snout_db/actions/write_matchtrace.dart';
import 'package:snout_db/event/robot_match_trace.dart';
import 'package:snout_db/match_trace.dart';
import 'package:snout_db/snout_chain.dart';
import 'package:test/test.dart';

import '../keypair.dart';

void main() async {
  final keyPair = await testGenKey();
  final rootKeypairAction = await testGetKeyPairAction(pair: keyPair);

  final traceData = RobotMatchTraceData.fromJson(
    jsonDecode(await File('test_resources/robot_trace.json').readAsString())
        as Map<String, dynamic>,
  );

  final trace = MatchTrace(match: 'qm1', team: 6749, trace: traceData);

  test('add trace', () async {
    final db = SnoutChain([rootKeypairAction]);

    final writeConfigAction = await ChainActionData(
      time: DateTime.now(),
      previousHash: await rootKeypairAction.hash,
      action: ActionWriteMatchTrace(trace),
    ).encodeAndSign(await keyPair.extractPrivateKeyBytes());

    await db.verifyApplyAction(writeConfigAction);

    expect(db.event.traces, contains(trace.uniqueKey));
  });

  test('remove non-existent trace', () async {
    final db = SnoutChain([rootKeypairAction]);

    final removeAction = await ChainActionData(
      time: DateTime.now(),
      previousHash: await rootKeypairAction.hash,
      action: ActionWriteMatchTrace(
        MatchTrace(match: 'qm1', team: 6749, trace: null),
      ),
    ).encodeAndSign(await keyPair.extractPrivateKeyBytes());

    await db.verifyApplyAction(removeAction);

    expect(db.event.traces, isNot(contains(trace.uniqueKey)));
  });

  test('remove trace', () async {
    final db = SnoutChain([rootKeypairAction]);

    final writeConfigAction = await ChainActionData(
      time: DateTime.now(),
      previousHash: await rootKeypairAction.hash,
      action: ActionWriteMatchTrace(trace),
    ).encodeAndSign(await keyPair.extractPrivateKeyBytes());

    final removeAction = await ChainActionData(
      time: DateTime.now(),
      previousHash: await writeConfigAction.hash,
      action: ActionWriteMatchTrace(
        MatchTrace(match: 'qm1', team: 6749, trace: null),
      ),
    ).encodeAndSign(await keyPair.extractPrivateKeyBytes());

    await db.verifyApplyAction(writeConfigAction);
    await db.verifyApplyAction(removeAction);

    expect(db.event.traces, isNot(contains(trace.uniqueKey)));
  });
}
