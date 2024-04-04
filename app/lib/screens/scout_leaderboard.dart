import 'dart:collection';

import 'package:app/providers/data_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

//TODO improve this page to make it less jank
class ScoutLeaderboardPage extends StatelessWidget {
  const ScoutLeaderboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>().database.patches;

    final expression = RegExp(r'\/matches\/.+\/robot\/');

    Map<String, int> scores = SplayTreeMap<String, int>();
    Map<String, int> edits = SplayTreeMap<String, int>();

    for (final patch in data) {
      if (scores[patch.identity] == null) {
        scores[patch.identity] = 0;
        edits[patch.identity] = 0;
      }

      int addValue = 1;
      if (expression.hasMatch(patch.path)) {
        addValue = 5;
      }

      edits[patch.identity] = edits[patch.identity]! + 1;
      scores[patch.identity] = scores[patch.identity]! + addValue;
    }

    print(scores);

    List<({String identity, int score, int edits})> sorted = [
      for (final scout in scores.entries)
        (
          identity: scout.key,
          score: scout.value,
          edits: edits[scout.key]!,
        ),
    ];

    sorted.sort((k1, k2) => k2.score.compareTo(k1.score));

    return Scaffold(
      appBar: AppBar(
        title: const Text("Edits Leaderboard"),
      ),
      body: ListView(
        children: [
          const Text(
              "This is just for fun! Each normal edit is worth 1 point (pit scouting is worth 1 point per field). A edits that match 'r'\\/matches\\/.+\\/robot\\/'' are worth 5 points because match recordings take longer."),
          for (final item in sorted)
            ListTile(
              title: Text(item.identity),
              subtitle: Text("Score: ${item.score}\nEdits: ${item.edits}"),
            )
        ],
      ),
    );
  }
}
