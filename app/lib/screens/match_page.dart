import 'dart:convert';

import 'package:app/api.dart';
import 'package:app/data/matches.dart';
import 'package:app/data/timeline_event.dart';
import 'package:app/edit_lock.dart';
import 'package:app/main.dart';
import 'package:app/map_viewer.dart';
import 'package:app/screens/edit_match_results.dart';
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
          body: FutureBuilder<Match>(
              future: getMatch(widget.match.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const CircularProgressIndicator.adaptive();
                }
                return TabBarView(children: [
                  _buildMatchView(snapshot.data!, null),
                  _buildMatchView(snapshot.data!, snapshot.data!.red[0]),
                  _buildMatchView(snapshot.data!, snapshot.data!.red[1]),
                  _buildMatchView(snapshot.data!, snapshot.data!.red[2]),
                  _buildMatchView(snapshot.data!, snapshot.data!.blue[0]),
                  _buildMatchView(snapshot.data!, snapshot.data!.blue[1]),
                  _buildMatchView(snapshot.data!, snapshot.data!.blue[2]),
                ]);
              }),
        ));
  }

  Widget _buildMatchView(Match data, int? teamNumber) {
    if (teamNumber == null) {
      return Column(
        children: [
          SizedBox(
            height: 50,
            child: Center(
              child: ElevatedButton(
                child: data.results == null
                    ? Text("Add Results")
                    : Text("Edit results"),
                onPressed: () async {
                  var result = await navigateWithEditLock(
                      context,
                      "match:${data.id}:results",
                      () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditMatchResults(
                                match: data, config: snoutData.config!),
                          )));

                  if (result == true) {
                    setState(() {});
                  }
                },
              ),
            ),
          ),
          if (data.results != null)
            SizedBox(
              width: 200,
              child: Table(
                children: [
                  TableRow(children: [
                    Text(""),
                    Text("Red"),
                    Text("Blue"),
                  ]),
                  for (final type in snoutData.config!.matchScouting.results)
                    TableRow(children: [
                      Text(type),
                      Text(data.results!.red.values[type].toString()),
                      Text(data.results!.blue.values[type].toString()),
                    ]),
                ],
              ),
            ),


            //Display a 'heatmap' of all of the events
            FieldMapViewer(
              events: [
                for(var timeline in data.timelines.keys)
                  ...?data.timelines[timeline]?.events,
              ],
              onTap: (position) {

              },
            ),
        ],
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 50,
          child: Center(
            child: ElevatedButton(
              child: Text("Record Match"),
              onPressed: () async {
                List<TimelineEvent>? result = await navigateWithEditLock(
                    context,
                    "match:${data.id}:$teamNumber:timeline",
                    () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  MatchRecorderPage(title: "Team $teamNumber")),
                        ));

                if (result != null) {
                  final data = {
                    "scout": await getName(),
                    "time": DateTime.now().toIso8601String(),
                    "events": result,
                  };

                  var asdf = await apiClient.post(
                      Uri.parse("${await getServer()}/match_timeline"),
                      headers: {
                        "jsondata": jsonEncode(data),
                        "id": widget.match.id,
                        "team": teamNumber.toString(),
                      });
                  setState(() {
                    
                  });
                }
              },
            ),
          ),
        ),
      ],
    );
  }
}

Future<Match> getMatch(String matchId) async {
  var res =
      await apiClient.get(Uri.parse("${await getServer()}/match"), headers: {
    "id": matchId,
  });
  print(res.body);
  return Match.fromJson(jsonDecode(res.body));
}
