import 'dart:convert';
import 'dart:typed_data';

import 'package:cbor/cbor.dart';
import 'package:snout_db/message.dart';
import 'package:snout_db/snout_chain.dart';

/// Client storage format for snoutdb
class ClientSnoutDb {
  /// Cannonical list of message hashes in the database (ordered)
  /// This can include messages that are not yet downloaded!
  List<List<int>> messageHashes;

  /// Map of message data downloaded
  Map<String, SignedChainMessage> messages;

  ClientSnoutDb({required this.messageHashes, required this.messages});

  CborValue toCbor() {
    return CborMap({
      CborString('messageHashes'): CborList(
        messageHashes.map((e) => CborBytes(e)).toList(),
      ),
      CborString('messages'): CborMap(
        messages.map((key, value) => MapEntry(CborString(key), value.toCbor())),
      ),
    });
  }

  SnoutChain toDbFile() {
    return SnoutChain(
      messageHashes.map((e) => messages[base64UrlEncode(e)]).nonNulls.toList(),
    );
  }

  static ClientSnoutDb fromCbor(CborValue cbor) {
    final map = cbor as CborMap;
    final messageHashesCbor = (map[CborString('messageHashes')]! as CborList)
        .map((e) => (e as CborBytes).bytes);
    final messagesCbor = Map.from(map[CborString('messages')]! as CborMap);

    return ClientSnoutDb(
      messageHashes: messageHashesCbor.toList(),
      messages: Map.fromEntries(
        messagesCbor.entries.map(
          (e) =>
              MapEntry(e.key.toString(), SignedChainMessage.fromCbor(e.value)),
        ),
      ),
    );
  }
}
