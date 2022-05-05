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
    return ListView(
      shrinkWrap: true,
      children: [
        MatchCard(),
        MatchCard(),
        MatchCard(),
        MatchCard(),
        MatchCard(),
        MatchCard(),
        MatchCard(),
        MatchCard(),
      ],
    );
  }
}
