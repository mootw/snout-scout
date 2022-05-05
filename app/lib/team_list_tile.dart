import 'package:app/view_team_page.dart';
import 'package:flutter/material.dart';

class TeamListTile extends StatelessWidget {
  const TeamListTile({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text("6749"),
      subtitle: Text("terabytes"),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const TeamViewPage()),
        );
      },
    );
  }
}
