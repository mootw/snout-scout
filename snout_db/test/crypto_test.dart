import 'dart:convert';
import 'dart:typed_data';

import 'package:snout_db/crypto.dart';
import 'package:test/test.dart';
import 'package:webcrypto/webcrypto.dart';

void main() {
  test('e2e secret key encryption', () async {
    final password = [1, 2, 3, 4, 5];

    final seed = Uint8List(32);
    fillRandomBytes(seed);

    print(base64Encode(seed));
    final a = await encryptSeedKey(seedKey: seed, password: password);
    print(a);
    final b = await decryptSeedKey(seedKey: a, password: password);
    print(base64Encode(b));

    expect(b, equals(seed));
  });
}
