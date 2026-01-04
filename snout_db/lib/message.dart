import 'package:cbor/cbor.dart';
import 'package:cryptography/cryptography.dart' as cryptography;
import 'package:cryptography/dart.dart';
import 'package:snout_db/action.dart';
import 'package:snout_db/pubkey.dart';

/// EdDSA25519 with SHA512 prehash
/// they canonincally encoded using CBOR as a map with integer keys to minimize overhead
/// Note, the only cannonical payload is the [payloadBytes]
/// The [payload] is just a decoded version for easy access
/// re-encoding is not guaranteed to be byte-identical!!
class SignedChainMessage {
  static final ed25519 = cryptography.Ed25519();
  static Future<List<int>> _prehash(List<int> input) async {
    return (await const DartSha512().hash(input)).bytes;
  }

  /// Public key of the author who created this message
  Pubkey author;

  /// Byte content
  List<int> payloadBytes;

  ChainActionData payload;

  /// Ed25519 signature of (previousHash || content)
  List<int> signature;

  SignedChainMessage(this.author, this.payloadBytes, this.signature)
    : payload = ChainActionData.fromCbor(cbor.decode(payloadBytes) as CborMap);

  SignedChainMessage.fromChainActionData(
    this.author,
    this.payload,
    this.signature,
  ) : payloadBytes = cbor.encode(payload.toCbor());

  /// Hash of this message sha256(author || content || signature)
  Future<List<int>> get hash async {
    return (await cryptography.Sha256().hash([
      ...author.bytes,
      ...payloadBytes,
      ...signature,
    ])).bytes;
  }

  /// Verifies that the Message is signed by the claiming author
  Future<bool> verify() async {
    final digest = await _prehash([...author.bytes, ...payloadBytes]);
    return await ed25519.verify(
      digest,
      signature: cryptography.Signature(
        signature,
        publicKey: cryptography.SimplePublicKey(
          author.bytes,
          type: ed25519.keyPairType,
        ),
      ),
    );
  }

  static Future<SignedChainMessage> createAndSign(
    List<int> payload,
    List<int> seedKey,
  ) async {
    final kp = await ed25519.newKeyPairFromSeed(seedKey);
    final author = (await kp.extractPublicKey()).bytes;
    final digest = await _prehash([...author, ...payload]);
    final wand = await ed25519.newSignatureWandFromKeyPair(kp);
    final sig = await wand.sign(digest);

    return SignedChainMessage(Pubkey(author), payload, sig.bytes);
  }

  CborMap toCbor() => CborMap({
    const CborSmallInt(1): CborBytes(author.bytes),
    const CborSmallInt(2): CborBytes(payloadBytes),
    const CborSmallInt(3): CborBytes(signature),
  });

  static SignedChainMessage fromCbor(CborMap map) {
    return SignedChainMessage(
      Pubkey((map[const CborSmallInt(1)]! as CborBytes).bytes),
      (map[const CborSmallInt(2)]! as CborBytes).bytes,
      (map[const CborSmallInt(3)]! as CborBytes).bytes,
    );
  }
}
