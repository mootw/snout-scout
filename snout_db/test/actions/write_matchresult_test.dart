import 'package:snout_db/action.dart';
import 'package:snout_db/actions/write_matchresults.dart';
import 'package:snout_db/event/matchresults.dart';
import 'package:snout_db/match_result.dart';
import 'package:snout_db/snout_chain.dart';
import 'package:test/test.dart';

import '../keypair.dart';

void main() async {
  final keyPair = await testGenKey();
  final rootKeypairAction = await testGetKeyPairAction(pair: keyPair);

  final result = MatchResult(
    match: 'qm1',
    result: MatchResultValues(
      time: DateTime.now(),
      redScore: 10,
      blueScore: 15,
    ),
  );

  test('add result', () async {
    final db = SnoutChain([rootKeypairAction]);

    final writeConfigAction = await ChainActionData(
      time: DateTime.now(),
      previousHash: await rootKeypairAction.hash,
      action: ActionWriteMatchResults(result),
    ).encodeAndSign(await keyPair.extractPrivateKeyBytes());

    await db.verifyApplyAction(writeConfigAction);

    expect(db.event.matchResults, contains(result.uniqueKey));
  });

  test('remove non-existent result', () async {
    final db = SnoutChain([rootKeypairAction]);

    final removeAction = await ChainActionData(
      time: DateTime.now(),
      previousHash: await rootKeypairAction.hash,
      action: ActionWriteMatchResults(
        MatchResult(match: result.match, result: null),
      ),
    ).encodeAndSign(await keyPair.extractPrivateKeyBytes());

    await db.verifyApplyAction(removeAction);

    expect(db.event.matchResults, isNot(contains(result.uniqueKey)));
  });

  test('remove result', () async {
    final db = SnoutChain([rootKeypairAction]);

    final writeConfigAction = await ChainActionData(
      time: DateTime.now(),
      previousHash: await rootKeypairAction.hash,
      action: ActionWriteMatchResults(result),
    ).encodeAndSign(await keyPair.extractPrivateKeyBytes());

    final removeAction = await ChainActionData(
      time: DateTime.now(),
      previousHash: await writeConfigAction.hash,
      action: ActionWriteMatchResults(
        MatchResult(match: result.match, result: null),
      ),
    ).encodeAndSign(await keyPair.extractPrivateKeyBytes());

    await db.verifyApplyAction(writeConfigAction);
    await db.verifyApplyAction(removeAction);

    expect(db.event.matchResults, isNot(contains(result.uniqueKey)));
  });
}
