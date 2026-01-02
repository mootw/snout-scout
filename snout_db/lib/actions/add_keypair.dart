import 'dart:convert';

import 'package:cbor/cbor.dart';
import 'package:snout_db/action.dart';
import 'package:snout_db/message.dart';
import 'package:snout_db/pubkey.dart';
import 'package:snout_db/secret_key.dart';
import 'package:snout_db/snout_chain.dart';

class ActionWriteKeyPair implements ChainAction {
  static const int typeId = 1;
  @override
  int get id => typeId;

  /// Public key
  final Pubkey pk;

  /// Encrypted private key
  final EncryptedSecretKey sk;

  final String alias;

  ActionWriteKeyPair(this.sk, this.pk, this.alias);

  @override
  CborValue toCbor() => CborMap({
    CborString("sk"): CborString(json.encode(sk.toJson())),
    CborString("pk"): CborBytes(pk.bytes),
    CborString("alias"): CborString(alias),
  });

  static ActionWriteKeyPair fromCbor(CborValue data) {
    final map = data as CborMap;
    return ActionWriteKeyPair(
      EncryptedSecretKey.fromJson(
        json.decode((map[CborString("sk")]! as CborString).toString())
            as Map<String, dynamic>,
      ),
      Pubkey((map[CborString("pk")]! as CborBytes).bytes),
      (map[CborString("alias")]! as CborString).toString(),
    );
  }

  @override
  String? isValid(SnoutChain chain, SignedChainMessage signee) {
    if (chain.actions.isEmpty) {
      // Always allow as first action
      return null;
    }

    if (chain.allowedKeys.keys.contains(pk)) {
      // Key already exists, do not overwrite!!
      // This might not actually be necessary
      // because we are comparing the pubkey to signed key and checking the signature
      return "Key already exists";
    }

    /// Only the first keypair is allowed to authorize adding new keypairs
    Pubkey? rootPubKey;
    for (final message in chain.actions) {
      final action = message.payload.action;
      if (action is ActionWriteKeyPair) {
        rootPubKey = action.pk;
        break;
      }
    }

    if (rootPubKey != null && rootPubKey == signee.author) {
      return null;
    } else {
      return "Only the root keypair is allowed to authorize adding new keypairs";
    }
  }

  @override
  void apply(SnoutChain chain, SignedChainMessage signee) {
    chain.allowedKeys[pk] = sk;
    chain.aliases[pk] = alias;
  }
}
