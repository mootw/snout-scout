import 'package:cbor/cbor.dart';
import 'package:snout_db/action.dart';
import 'package:snout_db/event/match_data.dart';
import 'package:snout_db/match_trace.dart';
import 'package:snout_db/message.dart';
import 'package:snout_db/snout_chain.dart';

/// Either Writes or nulls a match trace for a specific team in a specific match
class ActionWriteMatchTrace implements ChainAction {
  static const int typeId = 22;
  @override
  int get id => typeId;

  final MatchTrace trace;

  ActionWriteMatchTrace(this.trace);

  @override
  CborValue toCbor() => trace.toCbor();

  factory ActionWriteMatchTrace.fromCbor(CborValue data) {
    return ActionWriteMatchTrace(MatchTrace.fromCbor(data as CborMap));
  }

  @override
  String? isValid(SnoutChain db, SignedChainMessage signee) {
    return null;
  }

  @override
  void apply(SnoutChain db, SignedChainMessage signee) {
    if (trace.trace == null) {
      db.event.traces.remove(trace.uniqueKey);
    } else {
      db.event.traces[trace.uniqueKey] = (
        trace.trace!,
        signee.author,
        DateTime.now(),
      );
    }

    // Add trace to the legacy index of match data
    if (db.event.matches.containsKey(trace.match) == false) {
      db.event.matches[trace.match] = MatchData(robot: {});
    }
    if (db.event.matches[trace.match]!.robot.containsKey(
          trace.team.toString(),
        ) ==
        false) {
      if (trace.trace == null) {
        db.event.matches[trace.match]!.robot.remove(trace.team.toString());
      } else {
        db.event.matches[trace.match]!.robot[trace.team.toString()] =
            trace.trace!;
      }
    }
  }

  @override
  String toString() => 'ActionWriteMatchTrace(${trace.uniqueKey})';
}
