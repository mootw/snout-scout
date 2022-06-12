import 'package:app/data/matches.dart';
import 'package:app/edit_lock.dart';
import 'package:app/screens/match_recorder.dart';
import 'package:flutter/material.dart';

class MatchPage extends StatefulWidget {
  const MatchPage({required this.match, Key? key}) : super(key: key);

  final Match match;

  @override
  State<MatchPage> createState() => _MatchPageState();
}

class _MatchPageState extends State<MatchPage> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
        length: 7,
        child: Scaffold(
          appBar: AppBar(
            bottom: TabBar(
              isScrollable: true,
              tabs: [
                Tab(icon: Icon(Icons.videogame_asset)),
                Tab(
                    child: Text("${widget.match.red[0]}",
                        style: TextStyle(color: Colors.redAccent))),
                Tab(
                    child: Text("${widget.match.red[1]}",
                        style: TextStyle(color: Colors.redAccent))),
                Tab(
                    child: Text("${widget.match.red[2]}",
                        style: TextStyle(color: Colors.redAccent))),
                Tab(
                    child: Text("${widget.match.blue[0]}",
                        style: TextStyle(color: Colors.blueAccent))),
                Tab(
                    child: Text("${widget.match.blue[1]}",
                        style: TextStyle(color: Colors.blueAccent))),
                Tab(
                    child: Text("${widget.match.blue[2]}",
                        style: TextStyle(color: Colors.blueAccent))),
              ],
            ),
            title: Text("Match ${widget.match.section} ${widget.match.number}"),
          ),
          body: TabBarView(children: [
            MatchView(match: widget.match, teamNumber: null),
            MatchView(match: widget.match, teamNumber: widget.match.red[0]),
            MatchView(match: widget.match, teamNumber: widget.match.red[1]),
            MatchView(match: widget.match, teamNumber: widget.match.red[2]),
            MatchView(match: widget.match, teamNumber: widget.match.blue[0]),
            MatchView(match: widget.match, teamNumber: widget.match.blue[1]),
            MatchView(match: widget.match, teamNumber: widget.match.blue[2]),
          ]),
        ));
  }
}

class MatchView extends StatelessWidget {
  final Match match;
  final int? teamNumber;

  const MatchView({required this.match, required this.teamNumber, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (teamNumber == null) {
      return Column(
        children: [
          ElevatedButton(
            child: Text("record results"),
            onPressed: () {},
          ),
        ],
      );
    }

    return Column(
      children: [
        ElevatedButton(
          child: Text("record match"),
          onPressed: () async {
            var result = await navigateWithEditLock(
                context,
                "match:${match.section}${match.number}:$teamNumber:timeline",
                () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => MatchRecorderPage()),
                    ));
          },
        ),
        ElevatedButton(
          child: Text("edit timeline"),
          onPressed: () {},
        ),
      ],
    );
  }
}
