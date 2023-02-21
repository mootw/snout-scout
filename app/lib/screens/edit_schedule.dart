import 'dart:convert';

import 'package:app/api.dart';
import 'package:app/main.dart';
import 'package:app/screens/edit_json.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:snout_db/event/match.dart';
import 'package:snout_db/patch.dart';

class EditSchedulePage extends StatefulWidget {
  const EditSchedulePage({super.key, required this.matches});

  final Map<String, FRCMatch> matches;

  @override
  State<EditSchedulePage> createState() => _EditSchedulePageState();
}

class _EditSchedulePageState extends State<EditSchedulePage> {
  late Map<String, FRCMatch> matchesEdited;

  int i = 0;

  @override
  void initState() {
    super.initState();
    matchesEdited = widget.matches;
  }

  @override
  Widget build(BuildContext context) {
    final snoutData = context.watch<EventDB>();
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Schedule"),
        actions: [
          TextButton(
            child: const Text("LOAD MATCHES FROM FRCAPI"),
            onPressed: () async {
              final result = await apiClient.get(
                  Uri.parse(serverURL.replaceFirst("events", "load_schedule")));
              
              showDialog(context: context, builder: (context) {
                return AlertDialog(
                  title: Text(result.statusCode.toString()),
                  content: Text(result.body),
                );
              });
            },
          )
        ],
      ),
      body: ListView(children: [
        const Text(
            "Warning: Editing the schedule is potentially destructive! Data could be lost if the edit removes matches or a match was edited in-between some sub-edit"),
        for (final match in snoutData.db.matches.entries)
          ListTile(
            title: Text(match.value.description),
            subtitle: Text(match.key),
            onTap: () => editMatch(match.value, snoutData, match.key),
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () async {
                final result = await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                          title: const Text(
                              "Are you sure you want to remove this match?"),
                          actions: [
                            TextButton(
                                child: const Text("No"),
                                onPressed: () =>
                                    Navigator.of(context).pop(false)),
                            TextButton(
                              child: const Text("Yes"),
                              onPressed: () => Navigator.of(context).pop(true),
                            )
                          ],
                        ));
                if (result == true) {
                  final matchesWithRemoved = Map.from(snoutData.db.matches);
                  matchesWithRemoved.remove(match.key);

                  Patch patch = Patch(
                      time: DateTime.now(),
                      path: [
                        'matches',
                      ],
                      data: jsonEncode(matchesWithRemoved));
                  await snoutData.addPatch(patch);
                }
              },
            ),
          ),
        Center(
          child: FilledButton(
              onPressed: () async {
                FRCMatch match = FRCMatch(
                    description: "Some name",
                    number: 0,
                    scheduledTime: DateTime.now(),
                    blue: [],
                    red: [],
                    results: null,
                    robot: {});

                await editMatch(match, snoutData, null);
              },
              child: const Text("Add Match")),
        ),
      ]),
    );
  }

  Future editMatch(FRCMatch match, EventDB snoutData, String? matchID) async {
    String? result = await Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => JSONEditor(
            source: const JsonEncoder.withIndent("    ").convert(match),
            validate: FRCMatch.fromJson)));

    if (result != null) {
      FRCMatch resultMatch = FRCMatch.fromJson(jsonDecode(result));
      Patch patch = Patch(
          time: DateTime.now(),
          path: [
            'matches',
            matchID ?? resultMatch.description,
          ],
          data: result);
      await snoutData.addPatch(patch);
    }
  }
}

//Details about the match like its scheduled time, level, description.
class EditMatchDetails extends StatefulWidget {
  const EditMatchDetails({super.key, required this.match});

  final FRCMatch match;

  @override
  State<EditMatchDetails> createState() => EditMatchDetailsState();
}

class EditMatchDetailsState extends State<EditMatchDetails> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Match"),
      actions: [
        TextButton(
            onPressed: () {
              Navigator.of(context).pop(widget.match);
            },
            child: const Text("Save"))
      ],
    );
  }
}
