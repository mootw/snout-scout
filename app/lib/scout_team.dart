import 'dart:convert';

import 'package:app/main.dart';
import 'package:app/scouting_tools/scouting_tool.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:snout_db/event/pitscoutresult.dart';
import 'package:snout_db/patch.dart';
import 'package:snout_db/snout_db.dart';

class PitScoutTeamPage extends StatefulWidget {
  final int team;
  final Season config;
  final PitScoutResult? oldData;

  const PitScoutTeamPage(
      {Key? key, required this.team, required this.config, this.oldData})
      : super(key: key);

  @override
  State<PitScoutTeamPage> createState() => _PitScoutTeamPageState();
}

class _PitScoutTeamPageState extends State<PitScoutTeamPage> {

  PitScoutResult results = {};

  @override
  void initState() {
    super.initState();

    //populate existing data to pre-fill.
    if(widget.oldData != null) {
      results.addAll(widget.oldData!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
              onPressed: () async {
                //TODO this is probably not the right way to do state managment
                var snoutData = Provider.of<SnoutScoutData>(context, listen: false);

                Patch patch = Patch(
                    user: "anon",
                    time: DateTime.now(),
                    path: [
                      'events',
                      snoutData.selectedEventID,
                      'pitscouting',
                      widget.team.toString()
                    ],
                    data: jsonEncode(results));
                
                //Save the scouting results to the server!!
                var result = await snoutData.addPatch(patch);
                
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Saved Scouting Data'),
                  duration: Duration(seconds: 4),
                ));
                Navigator.of(context).pop(true);
                
              },
              icon: const Icon(Icons.save))
        ],
        title: Text("Scouting ${widget.team}"),
      ),
      body: ListView(
        shrinkWrap: true,
        children: [
          for (var item in widget.config.pitscouting)
            Container(
                padding: const EdgeInsets.all(12),
                child: ScoutingToolWidget(
                  tool: item,
                  survey: results,
                )),
        ],
      ),
    );
  }
}
