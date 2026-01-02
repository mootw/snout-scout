import 'dart:convert';

import 'package:app/data_submit_login.dart';
import 'package:app/providers/data_provider.dart';
import 'package:app/screens/edit_json.dart';
import 'package:app/screens/view_team_page.dart';
import 'package:app/services/snout_image_cache.dart';
import 'package:app/services/tba_autofill.dart';
import 'package:app/widgets/team_avatar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:snout_db/actions/write_teams.dart';

/// Displays a wrapped grid of teams
class TeamGridList extends StatefulWidget {
  const TeamGridList({super.key, this.teamFilter, this.showEditButton = false});

  final List<int>? teamFilter;
  final bool showEditButton;

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
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.spaceEvenly,
          children: [
            for (final team in context.watch<DataProvider>().event.teams)
              if (widget.teamFilter == null ||
                  widget.teamFilter!.contains(team))
                TeamListTile(
                  teamNumber: team,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TeamViewPage(teamNumber: team),
                      ),
                    );
                  },
                ),
            if (widget.showEditButton)
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
                                        .event
                                        .teams,
                                  ),
                                ),
                              );

                              final teams = List<int>.from(json.decode(result));
                              teams.sort();

                              if (result != null && context.mounted) {
                                final action = ActionWriteTeams(teams);
                                //Save the scouting results to the server!!
                                await submitData(context, action);
                              }
                            },
                            child: const Text("Manual"),
                          ),
                          TextButton(
                            onPressed: () async {
                              List<int> teams;
                              try {
                                teams = await getTeamListForEventTBA(
                                  context.read<DataProvider>().event,
                                );
                                //Some reason the teams do not come sorted...
                                teams.sort();
                              } catch (e) {
                                if (context.mounted) {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: Text(e.toString()),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: const Text("Ok"),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                                return;
                              }
                              if (!context.mounted) {
                                return;
                              }

                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => JSONEditor(
                                    validate: (item) {},
                                    source: teams,
                                  ),
                                ),
                              );

                              if (result != null && context.mounted) {
                                final action = ActionWriteTeams(
                                  json.decode(result) as List<int>,
                                );
                                //Save the scouting results to the server!!
                                await submitData(context, action);
                              }
                            },
                            child: const Text("TBA AutoFill"),
                          ),
                        ],
                      ),
                    ),
                    child: const Text("Edit Teams"),
                  ),
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
  final GestureTapCallback onTap;

  const TeamListTile({
    super.key,
    required this.teamNumber,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final snoutData = context.watch<DataProvider>();

    Widget? image;
    final data = snoutData
        .event
        .pitscouting[teamNumber.toString()]?[robotPictureReserved];
    if (data != null) {
      image = AspectRatio(
        aspectRatio: 1,
        child: Image(image: memoryImageProvider(data), fit: BoxFit.cover),
      );
    }

    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 160,
            height: 160,
            color: Colors.black38,
            child: image ?? const Center(child: Text("No Image")),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FRCTeamAvatar(teamNumber: teamNumber),
              const SizedBox(width: 4),
              Text(
                teamNumber.toString(),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
