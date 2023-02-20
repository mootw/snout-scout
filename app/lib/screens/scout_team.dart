import 'dart:convert';

import 'package:app/confirm_exit_dialog.dart';
import 'package:app/main.dart';
import 'package:app/scouting_tools/scouting_tool.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:snout_db/config/eventconfig.dart';
import 'package:snout_db/event/pitscoutresult.dart';
import 'package:snout_db/patch.dart';

class PitScoutTeamPage extends StatefulWidget {
  final int team;
  final EventConfig config;
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
    if (widget.oldData != null) {
      results.addAll(widget.oldData!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ConfirmExitDialog(
      child: Scaffold(
        appBar: AppBar(
          actions: [
            IconButton(
                onPressed: () async {
                  var snoutData = context.read<EventDB>();

                  Patch patch = Patch(
                      time: DateTime.now(),
                      path: ['pitscouting', widget.team.toString()],
                      data: jsonEncode(results));

                  //Save the scouting results to the server!!
                  await snoutData.addPatch(patch);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Saved Scouting Data'),
                      duration: Duration(seconds: 4),
                    ));
                    Navigator.of(context).pop(true);
                  }
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
      ),
    );
  }
}
