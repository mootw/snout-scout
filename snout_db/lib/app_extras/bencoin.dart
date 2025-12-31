import 'package:snout_db/actions/extras/battle_pass_upgrade.dart';
import 'package:snout_db/actions/write_dataitem.dart';
import 'package:snout_db/actions/write_matchresults.dart';
import 'package:snout_db/actions/write_matchtrace.dart';
import 'package:snout_db/pubkey.dart';
import 'package:snout_db/snout_chain.dart';

/// Unlocks 1 random reward from the battle pass
const lootCrateCost = 400;

/// Battle Levels start at 1, that is the cost to unlock that level
double battlePassCost(int level) => 50 + (level * 23);

/// This calculates bencoin distributions for a given scout based on their contributions
double bencoinDistributions(SnoutChain chain, Pubkey scout) {
  double totalBencoin = 0;
  for (final action in chain.actions) {
    if (action.author != scout) {
      continue;
    }

    switch (action.payload.action) {
      case ActionWriteMatchResults _:
        totalBencoin += 5;
        break;
      case ActionWriteMatchTrace _:
        totalBencoin += 35;
        break;
      case ActionWriteDataItem _:
        totalBencoin += 3;
        break;
      default:
        break;
    }
  }

  return totalBencoin;
}

double bencoinSpentByScout(SnoutChain chain, Pubkey scout) {
  double totalSpent = 0;

  for (final actionMessage in chain.actions) {
    if (actionMessage.author != scout) {
      continue;
    }

    final action = actionMessage.payload.action;
    if (action is ActionBattlePassLevelUp) {
      totalSpent += action.cost;
    }
  }

  return totalSpent;
}

double spendableBencoin(SnoutChain chain, Pubkey scout) {
  final distributions = bencoinDistributions(chain, scout);
  final spent = bencoinSpentByScout(chain, scout);
  return distributions - spent;
}
