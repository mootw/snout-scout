import 'dart:convert';
import 'dart:typed_data';

import 'package:app/main.dart';
import 'package:app/screens/view_team_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AllTeamsPage extends StatefulWidget {
  const AllTeamsPage({Key? key}) : super(key: key);

  @override
  State<AllTeamsPage> createState() => _AllTeamsPageState();
}

class _AllTeamsPageState extends State<AllTeamsPage> {

  @override
  Widget build(BuildContext context) {
    return Consumer<EventDB>(
      builder: (context, snoutData, child) {
        return SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Center(
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.spaceEvenly,
                  children: [
                    for (var team in snoutData.db.teams)
                      TeamListTile(teamNumber: team, snoutData: snoutData),
                  ],
                ),
          ),
        );
      }
    );
  }
}

class TeamListTile extends StatelessWidget {
  final int teamNumber;
  final EventDB snoutData;

  const TeamListTile({Key? key, required this.teamNumber, required this.snoutData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    
    Widget? image;
    var data = snoutData.db.pitscouting[teamNumber.toString()]?['robot_picture'];
    if (data!= null) {
      image = AspectRatio(
            aspectRatio: 1,
            child: Image.memory(Uint8List.fromList(
                base64Decode(data).cast<int>()), fit: BoxFit.cover));
    }

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => TeamViewPage(teamNumber: teamNumber)),
        );
      },
      child: Column(
        children: [
          Container(
            width: 150,
            height: 150,
            color: Colors.black38,
            child: image ?? const Center(child: Text("No Image")),
          ),
          const SizedBox(height: 4),
          Text(teamNumber.toString(), style: Theme.of(context).textTheme.titleMedium)
        ],
      ),
    );
  }
}
