import 'package:cbor/cbor.dart';
import 'package:snout_db/event/matchresults.dart';

class MatchResult {
  
  final String match;
  final MatchResultValues? result;

  String get uniqueKey => '/match/$match/result';

  MatchResult({required this.match, required this.result});

  CborValue toCbor() => CborMap({
    CborString('m'): CborString(match),
    CborString('r'): result == null ? const CborNull() : result!.toCbor(),
  });

  factory MatchResult.fromCbor(CborMap data) {
    final match = (data[CborString('m')]! as CborString).toString();
    final result = data[CborString('r')] is CborNull
        ? null
        : MatchResultValues.fromCbor(data[CborString('r')]!);
    return MatchResult(match: match, result: result);
  }
}
