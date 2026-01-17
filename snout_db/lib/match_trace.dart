import 'dart:convert';

import 'package:cbor/cbor.dart';
import 'package:snout_db/event/robot_match_trace.dart';

class MatchTrace {
  final String match;
  final int team;
  final RobotMatchTraceData? trace;

  String get uniqueKey => '/match/$match/trace/$team';

  MatchTrace({required this.match, required this.team, required this.trace});

  CborValue toCbor() => CborMap({
    CborString('m'): CborString(match),
    CborString('r'): CborSmallInt(team),
    CborString('t'): trace == null
        ? const CborNull()
        : CborString(json.encode(trace!.toJson())),
  });

  factory MatchTrace.fromCbor(CborMap data) {
    final match = (data[CborString('m')]! as CborString).toString();
    final robot = (data[CborString('r')]! as CborSmallInt).toInt();
    final trace = data[CborString('t')] is CborNull
        ? null
        : RobotMatchTraceData.fromJson(
            json.decode((data[CborString('t')]! as CborString).toString())
                as Map<String, dynamic>,
          );
    return MatchTrace(match: match, team: robot, trace: trace);
  }
}
