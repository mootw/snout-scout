import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:snout_db/action.dart';
import 'package:snout_db/actions/add_keypair.dart';
import 'package:snout_db/crypto.dart';
import 'package:snout_db/message.dart';
import 'package:snout_db/pubkey.dart';
import 'package:webcrypto/webcrypto.dart';

Future<SimpleKeyPair> testGenKey() async {
  final seed = Uint8List(32);
  fillRandomBytes(seed);
  final keyPair = await Ed25519().newKeyPairFromSeed(seed);
  return keyPair;
}

// Self signed keypair action, OR signed by another keypair
Future<SignedChainMessage> testGetKeyPairAction({
  required SimpleKeyPair pair,
  SimpleKeyPair? signedBy,
  List<int>? previousHash,
}) async {
  final rootKeypairAction =
      await ChainActionData(
        time: DateTime.now(),
        previousHash: previousHash ?? Uint8List(32),
        action: ActionWriteKeyPair(
          await encryptSeedKey(
            seedKey: await pair.extractPrivateKeyBytes(),
            password: [1, 2, 3],
          ),
          await pair.extractPublicKey().then((value) => Pubkey(value.bytes)),
          'test-keypair',
        ),
      ).encodeAndSign(
        await signedBy?.extractPrivateKeyBytes() ??
            await pair.extractPrivateKeyBytes(),
      );
  return rootKeypairAction;
}
