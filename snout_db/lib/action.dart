import 'package:cbor/cbor.dart';
import 'package:collection/collection.dart';
import 'package:snout_db/actions/add_keypair.dart';
import 'package:snout_db/actions/write_config.dart';
import 'package:snout_db/actions/write_dataitem.dart';
import 'package:snout_db/actions/write_matchresults.dart';
import 'package:snout_db/actions/write_matchtrace.dart';
import 'package:snout_db/actions/write_schedule.dart';
import 'package:snout_db/actions/write_teams.dart';
import 'package:snout_db/message.dart';
import 'package:snout_db/snout_chain.dart';

abstract interface class ChainAction {
  /// The ID of this action type
  int get id;

  CborValue toCbor();

  /// Verifies that this action can be performed on the given database.
  /// This Action should verify that the content of the action is valid
  /// given the current state of the database and that the signee is authorized
  /// to perform this action.
  bool isValid(SnoutChain db, SignedChainMessage signee);

  /// Applies this action to the database without any verification.
  void apply(SnoutChain db, SignedChainMessage signee);
}

typedef ActionFactory = ChainAction Function(CborValue data);

enum ActionType {
  addKeyPair(ActionWriteKeyPair.typeId, ActionWriteKeyPair.fromCbor),
  writeConfig(ActionWriteConfig.typeId, ActionWriteConfig.fromCbor),
  writeTeams(ActionWriteTeams.typeId, ActionWriteTeams.fromCbor),
  writeDataItem(ActionWriteDataItem.typeId, ActionWriteDataItem.fromCbor),
  writeRobotTrace(ActionWriteMatchTrace.typeId, ActionWriteMatchTrace.fromCbor),
  writeSchedule(ActionWriteSchedule.typeId, ActionWriteSchedule.fromCbor),
  writeMatchresult(ActionWriteMatchResults.typeId, ActionWriteMatchResults.fromCbor);

  final int id;
  final ActionFactory factory;

  const ActionType(this.id, this.factory);

  static ActionType? fromId(int id) {
    final type = ActionType.values.firstWhereOrNull(
      (t) => t.id == id,
    );
    return type;
  }

  static ChainAction create(int id, CborValue data) {
    final type = ActionType.values.firstWhere(
      (t) => t.id == id,
      orElse: () => throw Exception("Unknown Action ID: $id"),
    );
    return type.factory(data);
  }
}

class ChainActionData {
  /// Hash of the previous SignedChainMessage
  final List<int> previousHash;

  /// Time of this Actions's generation
  final DateTime time;

  final ChainAction action;

  ChainActionData({
    required this.time,
    required this.previousHash,
    required this.action,
  });

  Future<SignedChainMessage> encodeAndSign(List<int> seedKey) async {
    return await SignedChainMessage.createAndSign(cbor.encode(toCbor()), seedKey);
  }

  CborMap toCbor() => CborMap({
    const CborSmallInt(1): CborBytes(previousHash),
    const CborSmallInt(2): CborString(time.toUtc().toIso8601String()),
    const CborSmallInt(3): CborSmallInt(action.id),
    const CborSmallInt(4): action.toCbor(),
  });

  static ChainActionData fromCbor(CborMap map) {
    return ChainActionData(
      previousHash: (map[const CborSmallInt(1)]! as CborBytes).bytes,
      time: DateTime.parse(
        (map[const CborSmallInt(2)]! as CborString).toString(),
      ),
      action: ActionType.create(
        (map[const CborSmallInt(3)]! as CborSmallInt).value,
        map[const CborSmallInt(4)]!,
      ),
    );
  }
}
