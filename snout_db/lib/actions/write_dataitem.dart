import 'package:cbor/cbor.dart';
import 'package:snout_db/action.dart';
import 'package:snout_db/data_item.dart';
import 'package:snout_db/message.dart';
import 'package:snout_db/snout_chain.dart';

/// Either Writes or nulls a data value at a specific key for an entity.
class ActionWriteDataItem implements ChainAction {
  static const int typeId = 10;
  @override
  int get id => typeId;

  final DataItem dataItem;

  ActionWriteDataItem(this.dataItem);

  @override
  CborValue toCbor() => dataItem.toCbor();

  factory ActionWriteDataItem.fromCbor(CborValue data) {
    return ActionWriteDataItem(DataItem.fromCbor(data as CborMap));
  }

  @override
  String? isValid(SnoutChain db, SignedChainMessage signee) {
    return null;
  }

  @override
  void apply(SnoutChain db, SignedChainMessage signee) {
    if (dataItem.value == null) {
      db.event.dataItems.remove(dataItem.uniqueKey);
    } else {
      db.event.dataItems[dataItem.uniqueKey] = (
        dataItem,
        signee.author,
        DateTime.now(),
      );
    }
  }

  @override
  String toString() => 'ActionWriteDataItem(${dataItem.uniqueKey})';
}
