import 'package:cbor/cbor.dart';
import 'package:snout_db/message.dart';

/// This is the cannonical storage format for SnoutDB.
/// This is generally stored on disk, whether on a server, client, synced via peer to peer, or offline
/// If you are looking for
class SnoutDBFile {
  /// In-Order chain of all actions on this chain
  final List<SignedChainMessage> actions;

  /// this is the primary DB file, this contains all of the information needed
  /// to reconstruct the scouting data. BECAUSE the scouting data has unique
  /// requirements to data integrity, metadata, and auditing, we cannot just store
  /// the latest state of the database (this would be the easiest thing to do)
  /// rather we need to store the entire history of the database. for convenience
  /// a client can request the latest state, or patches, or both from the server.
  /// other metadata might get stored here too.
  SnoutDBFile({required this.actions});

  CborMap toCbor() {
    return CborMap({
      CborString('chain'): CborList(actions.map((e) => e.toCbor()).toList()),
    });
  }

  static SnoutDBFile fromCbor(CborMap db) {
    return SnoutDBFile(
      actions: List<CborMap>.from(
        db[CborString('chain')]! as CborList,
      ).map((e) => SignedChainMessage.fromCbor(e)).toList(),
    );
  }
}
