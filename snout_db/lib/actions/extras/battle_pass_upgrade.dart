import 'package:cbor/cbor.dart';
import 'package:collection/collection.dart';
import 'package:snout_db/action.dart';
import 'package:snout_db/app_extras/bencoin.dart';
import 'package:snout_db/message.dart';
import 'package:snout_db/snout_chain.dart';

class ActionBattlePassLevelUp implements ChainAction {
  static const int typeId = 900;
  @override
  int get id => typeId;

  final int level;
  final double cost;

  ActionBattlePassLevelUp(this.level) : cost = battlePassCost(level);

  @override
  CborValue toCbor() => CborMap({CborString("level"): CborSmallInt(level)});

  factory ActionBattlePassLevelUp.fromCbor(CborValue data) {
    final map = data as CborMap;
    return ActionBattlePassLevelUp(
      (map[CborString("level")]! as CborSmallInt).toInt(),
    );
  }

  @override
  String? isValid(SnoutChain db, SignedChainMessage signee) {
    final spendable = spendableBencoin(db, signee.author);

    // Require the scout to have enough spendable bencoin
    if (spendable < cost) {
      return "spendable bencoin ($spendable) is less than cost ($cost)";
    }

    // Require that the scout has the previous level
    final lastLevelUp = db.actions.lastWhereOrNull(
      (e) =>
          e.author == signee.author &&
          e.payload.action is ActionBattlePassLevelUp,
    );

    if (lastLevelUp != null &&
        (lastLevelUp.payload.action as ActionBattlePassLevelUp).level !=
            level - 1) {
      return "incorrect previous battle pass level ordering";
    }
    return null;
  }

  @override
  void apply(SnoutChain chain, SignedChainMessage signee) {
    chain.scoutBattlePassLevels[signee.author] = level;
  }
}
