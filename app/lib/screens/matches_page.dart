import 'package:app/api.dart';
import 'package:app/data/matches.dart';
import 'package:app/main.dart';
import 'package:app/match_card.dart';
import 'package:flutter/material.dart';

class AllMatchesPage extends StatefulWidget {
  const AllMatchesPage({Key? key}) : super(key: key);

  @override
  State<AllMatchesPage> createState() => _AllMatchesPageState();
}

class _AllMatchesPageState extends State<AllMatchesPage> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Match>>(
        future: getMatches(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            //Check for matches.

            return ListView(
              shrinkWrap: true,
              children: [
                for (var match in snapshot.data!) MatchCard(match: match),
              ],
            );
          }
          return const Center(child: CircularProgressIndicator.adaptive());
        });
  }
}

Future<List<Match>> getMatches({int? teamFilter}) async {
  var res = await apiClient.get(Uri.parse("${await getServer()}/matches"),
      headers: teamFilter != null
          ? {
              "team": "$teamFilter",
            }
          : null);
  return matchesFromJson(res.body);
}
