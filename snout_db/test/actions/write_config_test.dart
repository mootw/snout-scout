import 'package:snout_db/action.dart';
import 'package:snout_db/actions/write_config.dart';
import 'package:snout_db/snout_chain.dart';
import 'package:test/test.dart';

import '../keypair.dart';

void main() async {
  final keyPair = await testGenKey();
  final rootKeypairAction = await testGetKeyPairAction(pair: keyPair);

  test('writeConfig', () async {
    final db = SnoutChain([rootKeypairAction]);

    final writeConfigAction = await ChainActionData(
      time: DateTime.now(),
      previousHash: await rootKeypairAction.hash,
      action: ActionWriteConfig(
        const EventConfig(name: 'Test Event', team: 6749, fieldImage: ''),
      ),
    ).encodeAndSign(await keyPair.extractPrivateKeyBytes());

    await db.verifyApplyAction(writeConfigAction);

    print(db.event.config);

    expect(db.event.config.name, equals('Test Event'));
  });
}
