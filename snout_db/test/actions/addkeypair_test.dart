import 'package:snout_db/snout_chain.dart';
import 'package:test/test.dart';

import '../keypair.dart';

void main() async {
  final keyPair = await testGenKey();
  final secondKey = await testGenKey();

  final rootKeypairAction = await testGetKeyPairAction(pair: keyPair);
  final secondKeypairActionSelfSigned = await testGetKeyPairAction(
    pair: secondKey,
    previousHash: await rootKeypairAction.hash,
  );
  final secondKeypairActionSignedByRoot = await testGetKeyPairAction(
    pair: secondKey,
    signedBy: keyPair,
    previousHash: await rootKeypairAction.hash,
  );

  test('addkeypair', () async {
    final db = SnoutChain([]);
    await db.verifyApplyAction(rootKeypairAction);

    print(db.allowedKeys);

    expect(db.allowedKeys, isNotEmpty);
  });

  // Test to make sure that a keypair cannot add itself
  test('add self-signed keypair', () async {
    final db = SnoutChain([rootKeypairAction]);
    await expectLater(
      db.verifyApplyAction(secondKeypairActionSelfSigned),
      throwsException,
    );
    print(db.allowedKeys);
    expect(db.allowedKeys.length, equals(1));
  });

  test('add two keypairs', () async {
    final db = SnoutChain([rootKeypairAction]);
    await db.verifyApplyAction(secondKeypairActionSignedByRoot);

    print(db.allowedKeys);

    expect(db.allowedKeys.length, equals(2));
  });
}
