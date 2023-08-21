import 'dart:convert';
import 'dart:typed_data';

import 'package:app/providers/data_provider.dart';
import 'package:app/screens/edit_json.dart';
import 'package:app/screens/view_team_page.dart';
import 'package:app/services/tba_autofill.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:snout_db/patch.dart';

/// Displays a wrapped grid of teams
class TeamGridList extends StatefulWidget {
  const TeamGridList({super.key, this.teamFiler});

  final List<int>? teamFiler;

  @override
  State<TeamGridList> createState() => _TeamGridListState();
}

class _TeamGridListState extends State<TeamGridList> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: Center(
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.spaceEvenly,
          children: [
            for (final team in context.watch<DataProvider>().db.teams)
              if (widget.teamFiler == null || widget.teamFiler!.contains(team))
                TeamListTile(teamNumber: team),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: FilledButton.tonal(
                    onPressed: () => showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                              title: const Text("Edit Teams"),
                              actions: [
                                TextButton(
                                    onPressed: () async {
                                      final result = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => JSONEditor(
                                              validate: (item) {},
                                              source: context
                                                  .read<DataProvider>()
                                                  .db
                                                  .teams,
                                            ),
                                          ));

                                      if (result != null && mounted) {
                                        Patch patch = Patch(
                                            time: DateTime.now(),
                                            path: ['teams'],
                                            data: result);
                                        //Save the scouting results to the server!!
                                        await context
                                            .read<DataProvider>()
                                            .addPatch(patch);
                                      }
                                    },
                                    child: const Text("Manual")),
                                TextButton(
                                    onPressed: () async {
                                      List<int> teams;
                                      try {
                                        teams = await getTeamListForEventTBA(
                                            context.read<DataProvider>().db);
                                        //Some reason the teams do not come sorted...
                                        teams.sort();
                                      } catch (e) {
                                        if (mounted) {
                                          showDialog(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                    title: Text(e.toString()),
                                                    actions: [
                                                      TextButton(
                                                          onPressed: () =>
                                                              Navigator.pop(
                                                                  context),
                                                          child:
                                                              const Text("Ok"))
                                                    ],
                                                  ));
                                        }
                                        return;
                                      }
                                      if (!mounted) {
                                        return;
                                      }

                                      final result = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => JSONEditor(
                                              validate: (item) {},
                                              source: teams,
                                            ),
                                          ));

                                      if (result != null && mounted) {
                                        Patch patch = Patch(
                                            time: DateTime.now(),
                                            path: ['teams'],
                                            data: result);
                                        //Save the scouting results to the server!!
                                        await context
                                            .read<DataProvider>()
                                            .addPatch(patch);
                                      }
                                    },
                                    child: const Text("TBA AutoFill")),
                              ],
                            )),
                    child: const Text("Edit Teams")),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TeamListTile extends StatelessWidget {
  final int teamNumber;

  const TeamListTile({super.key, required this.teamNumber});

  @override
  Widget build(BuildContext context) {
    final snoutData = context.watch<DataProvider>();
    Widget? image;
    final data =
        snoutData.db.pitscouting[teamNumber.toString()]?['robot_picture'];
    if (data != null) {
      image = AspectRatio(
          aspectRatio: 1,
          child: Image.memory(
              Uint8List.fromList(base64Decode(data).cast<int>()),
              fit: BoxFit.cover));
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
          Text(teamNumber.toString(),
              style: Theme.of(context).textTheme.titleMedium)
        ],
      ),
    );
  }
}
