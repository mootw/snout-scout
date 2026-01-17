import 'dart:typed_data';

import 'package:cryptography/cryptography.dart' as cryptography;
import 'package:snout_db/action.dart';
import 'package:snout_db/actions/add_keypair.dart';
import 'package:snout_db/pubkey.dart';
import 'package:snout_db/secret_key.dart';
import 'package:webcrypto/webcrypto.dart';

void main(List<String> args) async {
  final ed25519 = cryptography.Ed25519();

  final seed = Uint8List(32);
  fillRandomBytes(seed);

  final pubKeyPair = await ed25519.newKeyPairFromSeed(seed);

  final chainAction = ChainActionData(
    time: DateTime.now(),
    previousHash: Uint8List(32),
    action: ActionWriteKeyPair(
      await encryptSeedKey(seedKey: [1, 2, 3], password: [1, 2, 3]),
      Pubkey((await pubKeyPair.extractPublicKey()).bytes),
      'Key Alias',
    ),
  );

  final signed = await chainAction.encodeAndSign(seed);
  print(signed.toCbor().toObject());
}

Future<EncryptedSecretKey> encryptSeedKey({
  required List<int> seedKey,
  required List<int> password,

  /// Difficulty target for PBKDF2
  int t = 210000,
}) async {
  final salt = Uint8List(16);
  fillRandomBytes(salt);

  final key = await Pbkdf2SecretKey.importRawKey(password);
  // derrive encryption key
  final dk = await key.deriveBits(256, Hash.sha256, salt, t);

  final iv = Uint8List(16);
  fillRandomBytes(iv);

  // Encrypt private key
  final aes256cbc = await AesCbcSecretKey.importRawKey(dk);

  return EncryptedSecretKey(
    salt: salt,
    iv: iv,
    protocol: 'aes-256-cbc',
    kd: 'pbkdf2',
    t: t,
    encryptedKey: await aes256cbc.encryptBytes(seedKey, iv),
  );
}

Future<List<int>> decryptSeedKey({
  required EncryptedSecretKey seedKey,
  required List<int> password,
}) async {
  final key = await Pbkdf2SecretKey.importRawKey(password);
  // derrive encryption key
  final dk = await key.deriveBits(256, Hash.sha256, seedKey.salt, seedKey.t);

  // Encrypt private key
  final aes_256_cbc = await AesCbcSecretKey.importRawKey(dk);
  return aes_256_cbc.decryptBytes(seedKey.encryptedKey, seedKey.iv);
}

/*
TODO follow this:?
https://datatracker.ietf.org/doc/html/rfc5208


openssl genpkey -algorithm ed25519 -aes256 -out private.pem

[spencer@thinn tmp]$ cat private.pem 
-----BEGIN ENCRYPTED PRIVATE KEY-----
MIGjMF8GCSqGSIb3DQEFDTBSMDEGCSqGSIb3DQEFDDAkBBC97ws1cnL0ltCw9MvZ
UDHFAgIIADAMBggqhkiG9w0CCQUAMB0GCWCGSAFlAwQBKgQQckyCo+IJIGrlLqyL
8dKjqgRASwzZQTDEZaGD4s7uN4Pr9v+EmLcOdusy4cm3QA5p28ffLGSnkn9QCQnK
gY+Icex7+J2wzEcpwPgeU0jUAglPTQ==
-----END ENCRYPTED PRIVATE KEY-----
[spencer@thinn tmp]$ openssl asn1parse -in private.pem 
    0:d=0  hl=3 l= 163 cons: SEQUENCE          
    3:d=1  hl=2 l=  95 cons: SEQUENCE          
    5:d=2  hl=2 l=   9 prim: OBJECT            :PBES2
   16:d=2  hl=2 l=  82 cons: SEQUENCE          
   18:d=3  hl=2 l=  49 cons: SEQUENCE          
   20:d=4  hl=2 l=   9 prim: OBJECT            :PBKDF2
   31:d=4  hl=2 l=  36 cons: SEQUENCE          
   33:d=5  hl=2 l=  16 prim: OCTET STRING      [HEX DUMP]:BDEF0B357272F496D0B0F4CBD95031C5
   51:d=5  hl=2 l=   2 prim: INTEGER           :0800
   55:d=5  hl=2 l=  12 cons: SEQUENCE          
   57:d=6  hl=2 l=   8 prim: OBJECT            :hmacWithSHA256
   67:d=6  hl=2 l=   0 prim: NULL              
   69:d=3  hl=2 l=  29 cons: SEQUENCE          
   71:d=4  hl=2 l=   9 prim: OBJECT            :aes-256-cbc
   82:d=4  hl=2 l=  16 prim: OCTET STRING      [HEX DUMP]:724C82A3E209206AE52EAC8BF1D2A3AA
  100:d=1  hl=2 l=  64 prim: OCTET STRING      [HEX DUMP]:4B0CD94130C465A183E2CEEE3783EBF6FF8498B70E76EB32E1C9B7400E69DBC7DF2C64A7927F500909CA818F8871EC7BF89DB0CC4729C0F81E5348D402094F4D
[spencer@thinn tmp]$ openssl pkey -in private.pem -text -noout
Enter pass phrase for private.pem:
ED25519 Private-Key:
priv:
    1b:31:33:d7:68:24:62:b9:87:8a:6b:a7:27:9d:d7:
    23:dc:7d:8c:b9:b8:10:b0:40:91:e8:39:e2:ac:7d:
    e8:a2
pub:
    21:e4:56:2c:5e:29:45:cc:93:fb:e5:51:b4:1b:43:
    b2:c7:b9:68:fd:ac:d0:f0:00:a9:78:a4:47:05:a9:
    0c:7e

*/
