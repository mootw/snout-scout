import 'package:cbor/cbor.dart';
import 'package:snout_db/action.dart';
import 'package:snout_db/message.dart';
import 'package:snout_db/snout_chain.dart';
import 'package:snout_db/strategy/team_list.dart';

class ActionWriteTeamList implements ChainAction {
  static const int typeId = 800;
  @override
  int get id => typeId;

  final TeamList list;

  ActionWriteTeamList(this.list);

  @override
  CborValue toCbor() =>
      CborMap({CborString("list"): CborBytes(cbor.encode(list.toCbor()))});

  factory ActionWriteTeamList.fromCbor(CborValue data) {
    final map = data as CborMap;
    return ActionWriteTeamList(
      TeamList.fromCbor(
        cbor.decode((map[CborString("list")]! as CborBytes).bytes) as CborMap,
      ),
    );
  }

  @override
  String? isValid(SnoutChain db, SignedChainMessage signee) {
    return null;
  }

  @override
  void apply(SnoutChain chain, SignedChainMessage signee) {
    chain.event.teamLists[list.name] = list;
  }
}
