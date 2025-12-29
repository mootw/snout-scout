import 'dart:collection';
import 'dart:math';

import 'package:app/providers/data_provider.dart';
import 'package:app/widgets/datasheet.dart';
import 'package:app/widgets/scout_name_display.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:snout_db/actions/write_matchtrace.dart';
import 'package:snout_db/pubkey.dart';

int sixOrSeven(int? seed) => Random(seed).nextBool() ? 6 : 7;

class ScoutLeaderboard extends StatelessWidget {
  const ScoutLeaderboard({super.key});

  @override
  Widget build(BuildContext context) {
    final db = context.watch<DataProvider>().database;
    final actions = db.actions;

    final scores = <Pubkey, int>{};
    final edits = <Pubkey, int>{};

    for (final actionMessage in actions) {
      final chainAction = actionMessage.payload;
      if (scores[actionMessage.author] == null) {
        scores[actionMessage.author] = 0;
        edits[actionMessage.author] = 0;
      }

      int addValue = 1;
      if (chainAction is ActionWriteMatchTrace) {
        // cursed seeding function
        addValue = sixOrSeven(actionMessage.payloadBytes.length);
      }

      edits[actionMessage.author] = edits[actionMessage.author]! + 1;
      scores[actionMessage.author] = scores[actionMessage.author]! + addValue;
    }

    List<({Pubkey identity, int score, int edits})> sorted = [
      for (final scout in scores.entries)
        (identity: scout.key, score: scout.value, edits: edits[scout.key]!),
    ];

    sorted.sort((k1, k2) => k2.score.compareTo(k1.score));

    int highScore = sorted.first.score;

    const height = 400.0;

    return Column(
      children: [
        const Text(
          "Each normal edit is worth 1 point. Match Traces are worth 6 or 7 points.",
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
                                height: item.score / highScore * height,
                              ),
                              Text(item.score.toString()),
                            ],
                          ),
                          Column(
                            children: [
                              Container(
                                width: 36,
                                color: Colors.blue,
                                height: item.edits / highScore * height,
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
          title: const Text("Score"),
        ),
        ListTile(
          leading: Container(height: 32, width: 32, color: Colors.blue),
          title: const Text("Edits"),
        ),
      ],
    );
  }
}
