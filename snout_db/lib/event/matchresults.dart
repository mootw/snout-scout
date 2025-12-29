import 'package:cbor/cbor.dart';
import 'package:snout_db/game.dart';

class MatchResultValues {
  ///the time when the match actually started
  final DateTime time;

  final int redScore;
  final int blueScore;

  const MatchResultValues({
    required this.time,
    required this.redScore,
    required this.blueScore,
  });

  static MatchResultValues fromCbor(CborValue value) {
    final map = value as CborMap;
    return MatchResultValues(
      time: DateTime.fromMillisecondsSinceEpoch(
        (map[CborString('time')]! as CborInt).toInt(),
      ),
      redScore: (map[CborString('redScore')]! as CborInt).toInt(),
      blueScore: (map[CborString('blueScore')]! as CborInt).toInt(),
    );
  }

  CborMap toCbor() => CborMap({
        CborString('time'): CborSmallInt(time.millisecondsSinceEpoch),
        CborString('redScore'): CborSmallInt(redScore),
        CborString('blueScore'): CborSmallInt(blueScore),
      });

  Alliance get winner {
    if (redScore == blueScore) {
      return Alliance.tie;
    }
    if (redScore > blueScore) {
      return Alliance.red;
    } else {
      return Alliance.blue;
    }
  }
}
