import 'package:app/main.dart';
import 'package:app/scout_team.dart';
import 'package:flutter/material.dart';

class TeamViewPage extends StatefulWidget {
  final int number;

  const TeamViewPage({Key? key, required this.number}) : super(key: key);

  @override
  State<TeamViewPage> createState() => _TeamViewPageState();
}

class _TeamViewPageState extends State<TeamViewPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          actions: [
            IconButton(
                onPressed: () {
                  var config = snoutData.scoutingConfig;
                  if (config != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => ScoutTeamPage(
                              team: widget.number, config: config)),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('scouting config not loaded'),
                      duration: Duration(seconds: 4),
                    ));
                  }
                },
                icon: Icon(Icons.edit_attributes))
          ],
          title: Text("Team ${widget.number}"),
        ),
        body: ListView(
          shrinkWrap: true,
          children: [
            Text("Scouting results"),
            Text("Matches"),
            Text("Performance Summary"),
            Text("")
          ],
        ));
  }
}
