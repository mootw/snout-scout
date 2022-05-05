import 'package:flutter/material.dart';

class TeamViewPage extends StatefulWidget {
  const TeamViewPage({Key? key}) : super(key: key);

  @override
  State<TeamViewPage> createState() => _TeamViewPageState();
}

class _TeamViewPageState extends State<TeamViewPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          actions: [
            IconButton(onPressed: () {}, icon: Icon(Icons.edit_attributes))
          ],
          title: Text("Team 6749"),
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
