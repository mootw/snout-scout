import 'dart:collection';
import 'dart:math' as math;

import 'package:snout_db/app_extras/bencoin.dart';
import 'package:app/providers/data_provider.dart';
import 'package:app/widgets/datasheet.dart';
import 'package:app/widgets/scout_name_display.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:snout_db/pubkey.dart';

class ScoutLeaderboard extends StatelessWidget {
  const ScoutLeaderboard({super.key});

  @override
  Widget build(BuildContext context) {
    final db = context.watch<DataProvider>().database;
    final actions = db.actions;

    final scouts = db.allowedKeys.keys;

    final bencoins = <Pubkey, double>{};
    final edits = <Pubkey, int>{};

    for (final scout in scouts) {
      bencoins[scout] = spendableBencoin(db, scout);
      edits[scout] = 0;
    }

    for (final actionMessage in actions) {
      edits[actionMessage.author] = (edits[actionMessage.author] ?? 0) + 1;
    }

    List<({Pubkey identity, double bencoin, int edits})> sorted = [
      for (final scout in bencoins.entries)
        (
          identity: scout.key,
          bencoin: scout.value,
          edits: edits[scout.key] ?? 0,
        ),
    ];

    sorted.sort((k1, k2) => k2.bencoin.compareTo(k1.bencoin));

    double highBencoin = math.max(sorted.first.bencoin, 100);
    double highEdits = math.max(
      sorted
          .sorted((k1, k2) => k2.edits.compareTo(k1.edits))
          .first
          .edits
          .toDouble(),
      10,
    );

    const height = 400.0;

    return Column(
      children: [
        const Text(
          "Earn Bencoin by Scouting and then predict matches. Remember it's not gambling if you know the outcome!",
        ),
        const SizedBox(height: 32),
        SizedBox(
          height: height + 40,
          child: ScrollConfiguration(
            behavior: MouseInteractableScrollBehavior(),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                const SizedBox(width: 24),
                for (final (idx, item) in sorted.indexed) ...[
                  Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          Text('${idx + 1}. '),
                          ScoutName(db: db, scoutPubkey: item.identity),
                        ],
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Column(
                            children: [
                              Container(
                                color: Colors.red,
                                width: 36,
                                height: item.bencoin / highBencoin * height,
                              ),
                              Text(item.bencoin.toString()),
                            ],
                          ),
                          Column(
                            children: [
                              Container(
                                width: 36,
                                color: Colors.blue,
                                height: item.edits / highEdits * height,
                              ),
                              Text(item.edits.toString()),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  const VerticalDivider(width: 4),
                ],
              ],
            ),
          ),
        ),
        ListTile(
          leading: Container(height: 32, width: 32, color: Colors.red),
          title: const Text("Bencoin"),
        ),
        ListTile(
          leading: Container(height: 32, width: 32, color: Colors.blue),
          title: const Text("Edits"),
        ),
      ],
    );
  }
}
