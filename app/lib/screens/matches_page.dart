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
    //TODO make page scroll to next match automatically
    return ListView(
      children: [
        for (var match in snoutData.currentEvent.matches)
          MatchCard(match: match, focusTeam: snoutData.season?.team),
      ],
    );
  }
}
