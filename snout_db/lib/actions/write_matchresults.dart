import 'package:cbor/cbor.dart';
import 'package:snout_db/action.dart';
import 'package:snout_db/match_result.dart';
import 'package:snout_db/message.dart';
import 'package:snout_db/snout_chain.dart';

/// Either Writes or nulls a match trace for a specific team in a specific match
class ActionWriteMatchResults implements ChainAction {
  static const int typeId = 24;
  @override
  int get id => typeId;

  final MatchResult matchResult;

  ActionWriteMatchResults(this.matchResult);

  @override
  CborValue toCbor() => matchResult.toCbor();

  static ActionWriteMatchResults fromCbor(CborValue data) {
    return ActionWriteMatchResults(MatchResult.fromCbor(data as CborMap));
  }

  @override
  String? isValid(SnoutChain db, SignedChainMessage signee) {
    return null;
  }

  @override
  void apply(SnoutChain db, SignedChainMessage signee) {
    if (matchResult.result == null) {
      db.event.matchResults.remove(matchResult.uniqueKey);
    } else {
      db.event.matchResults[matchResult.uniqueKey] = (
        matchResult.result!,
        signee.author,
        DateTime.now(),
      );
    }
  }

  @override
  String toString () => 'ActionWriteMatchResults(${matchResult.uniqueKey})';
}
