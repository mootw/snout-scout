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

    Map<String, int> scores = SplayTreeMap<String, int>();

    for(final patch in data) {
      if(scores[patch.identity] == null) {
        scores[patch.identity] = 0;
      }

      int addValue = 1;
      if(patch.path.startsWith("/matches")) {
        //MATCH SCOUTS ARE WORTH DOUBLE POINTS!
        addValue = 2;
      }

      scores[patch.identity] = scores[patch.identity]! + addValue;
    }

    var sortedByKeyMap = SplayTreeMap<String, int>.from(scores, (k1, k2) => scores[k2]!.compareTo(scores[k1]!));

    return Scaffold(
      appBar: AppBar(
        title: const Text("Edits Leaderboard"),
      ),
      body: ListView(
        children: [
          for(final item in sortedByKeyMap.entries)
            ListTile(
              title: Text(item.key),
              subtitle: Text("${item.value}"),
            )
        ],
      ),
    );
  }
}