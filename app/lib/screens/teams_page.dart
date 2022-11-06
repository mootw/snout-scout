import 'dart:convert';
import 'dart:typed_data';

import 'package:app/main.dart';
import 'package:app/screens/view_team_page.dart';
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
            for (var team in snoutData.currentEvent.teams)
              TeamListTile(teamNumber: team),
          ],
        );
  }
}

class TeamListTile extends StatelessWidget {
  final int teamNumber;

  const TeamListTile({Key? key, required this.teamNumber}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    
    Widget? image;
    var data = snoutData.currentEvent.pitscouting[teamNumber.toString()]?['robot_picture'];
    if (data!= null) {
      image = AspectRatio(
            aspectRatio: 1,
            child: Image.memory(Uint8List.fromList(
                base64Decode(data).cast<int>()), fit: BoxFit.cover));
    }

    return ListTile(
      subtitle: SizedBox(),
      leading: image,
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
