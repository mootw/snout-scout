import 'package:app/team_list_tile.dart';
import 'package:flutter/material.dart';

class AllTeamsPage extends StatefulWidget {
  const AllTeamsPage({Key? key}) : super(key: key);

  @override
  State<AllTeamsPage> createState() => All_TeamsPageState();
}

class All_TeamsPageState extends State<AllTeamsPage> {
  @override
  Widget build(BuildContext context) {
    return ListView(
      shrinkWrap: true,
      children: [
        TeamListTile(teamNumber: 6749),
        TeamListTile(teamNumber: 6749),
        TeamListTile(teamNumber: 6749),
        TeamListTile(teamNumber: 6749),
        TeamListTile(teamNumber: 6749),
        TeamListTile(teamNumber: 6749),
        TeamListTile(teamNumber: 6749),
        TeamListTile(teamNumber: 6749),
        TeamListTile(teamNumber: 6749),
        TeamListTile(teamNumber: 6749),
        TeamListTile(teamNumber: 6749),
        TeamListTile(teamNumber: 6749),
        TeamListTile(teamNumber: 6749),
        TeamListTile(teamNumber: 6749),
        TeamListTile(teamNumber: 6749),
        TeamListTile(teamNumber: 6749),
        TeamListTile(teamNumber: 6749),
        TeamListTile(teamNumber: 6749),
        TeamListTile(teamNumber: 6749),
        TeamListTile(teamNumber: 6749),
        TeamListTile(teamNumber: 6749),
        TeamListTile(teamNumber: 6749),
        TeamListTile(teamNumber: 6749),
      ],
    );
  }
}
