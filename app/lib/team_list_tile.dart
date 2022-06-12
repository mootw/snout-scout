import 'package:app/screens/view_team_page.dart';
import 'package:flutter/material.dart';

class TeamListTile extends StatelessWidget {
  final int teamNumber;

  const TeamListTile({Key? key, required this.teamNumber}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(teamNumber.toString()),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => TeamViewPage(number: teamNumber)),
        );
      },
    );
  }
}
