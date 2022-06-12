import 'package:flutter/material.dart';

class ScoutMatchPage extends StatefulWidget {
  const ScoutMatchPage({Key? key}) : super(key: key);

  @override
  State<ScoutMatchPage> createState() => _ScoutMatchPageState();
}

class _ScoutMatchPageState extends State<ScoutMatchPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Match 5 - Team 6749"),
        ),
        body: Column(
          children: [
            ElevatedButton(
              child: Text("pre game"),
              onPressed: () {},
            ),
            ElevatedButton(
              child: Text("record match"),
              onPressed: () {},
            ),
            ElevatedButton(
              child: Text("edit timeline"),
              onPressed: () {},
            ),
            ElevatedButton(
              child: Text("post game"),
              onPressed: () {},
            ),
          ],
        ));
  }
}
