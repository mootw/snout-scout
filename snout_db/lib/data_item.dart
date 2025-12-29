import 'package:cbor/cbor.dart';
import 'package:snout_db/config/data_item_schema.dart';

/// Essentially key-value elements that are based on a [DataItemSchema] schema and are referenced to an "Entity" (Team, Match, Trace, etc)
class DataItem {
  /// Id of the thing this is a part of
  String entity;

  /// Equal to the [DataItemSchema] metadata this data item represents
  String key;

  String get uniqueKey => '$entity/$key';

  Object? value;

  /// Basically pass the types down as-is, except convert int to double for consistent number handling.
  /// CBOR will store Uint8List as bytes, strings as strings, and doubles as numbers
  DataItem(this.entity, this.key, this.value);

  DataItem.pit(this.key, this.value) : entity = '/pit';

  DataItem.team(int team, this.key, this.value) : entity = '/team/$team';

  DataItem.match(String match, this.key, this.value) : entity = '/match/$match/data';

  DataItem.matchTeam(String match, int team, this.key, this.value)
    : entity = '/match/$match/team/$team';

  DataItem.fromCbor(CborMap item)
    : entity = (item[CborString('e')]! as CborString).toString(),
      key = (item[CborString('k')]! as CborString).toString(),
      value = item[CborString('v')]!.toObject();

  CborMap toCbor() => CborMap({
    CborString('e'): CborString(entity),
    CborString('k'): CborString(key),
    // Automatically handles nulls
    CborString('v'): CborValue(value),
  });
}
