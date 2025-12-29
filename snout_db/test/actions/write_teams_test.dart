import 'package:snout_db/action.dart';
import 'package:snout_db/actions/write_teams.dart';
import 'package:snout_db/snout_chain.dart';
import 'package:test/test.dart';

import '../keypair.dart';

void main() async {
  final keyPair = await testGenKey();
  final rootKeypairAction = await testGetKeyPairAction(pair: keyPair);

  test('write teams', () async {
    final db = SnoutChain([rootKeypairAction]);

    final teams = [1, 2, 3, 4, 5, 6, 7, 8, 9, 6749, 12000];

    final writeConfigAction = await ChainActionData(
      time: DateTime.now(),
      previousHash: await rootKeypairAction.hash,
      action: ActionWriteTeams(teams),
    ).encodeAndSign(await keyPair.extractPrivateKeyBytes());

    await db.verifyApplyAction(writeConfigAction);

    print(db.event.teams);

    expect(db.event.teams, equals(teams));
  });
}
