import 'dart:convert';

import 'package:app/providers/data_provider.dart';
import 'package:app/providers/identity_provider.dart';
import 'package:app/screens/edit_json.dart';
import 'package:app/services/tba_autofill.dart';
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
  @override
  Widget build(BuildContext context) {
    final snoutData = context.watch<DataProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Schedule"),
        actions: [
          TextButton(
            child: const Text("AutoFill TBA"),
            onPressed: () async {
              List<Patch> patch;
              try {
                patch = await loadScheduleFromTBA(snoutData.event, context);
              } catch (e) {
                if (mounted) {
                  showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: const Text("Error Getting From TBA"),
                          content: Text(e.toString()),
                        );
                      });
                }
                return;
              }

              if (mounted) {
                showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text("data"),
                        content: SingleChildScrollView(
                            child: Text(jsonEncode(patch))),
                        actions: [
                          TextButton(
                              onPressed: () async {
                                for (var p in patch) {
                                  await snoutData.addPatch(p);
                                }
                                if (mounted) {
                                  Navigator.pop(context);
                                }
                              },
                              child: const Text("Apply"))
                        ],
                      );
                    });
              }
            },
          ),
        ],
      ),
      body: ListView(children: [
        Text(
          "Warning: Editing the schedule is potentially incredibly destructive! Data could be lost if the edit removes matches or a match was edited in-between some sub-edit",
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
        Center(
          child: FilledButton(
              onPressed: () async {
                FRCMatch match = FRCMatch(
                    description: "description",
                    scheduledTime: DateTime.now(),
                    blue: [],
                    red: [],
                    results: null,
                    robot: {});

                await editMatch(match, snoutData, null);
              },
              child: const Text("Add Match")),
        ),
        for (final match in snoutData.event.matches.entries)
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
                          title: Text(
                              "Are you sure you want to delete ${match.value.description}?"),
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
                  final matchesWithRemoved = Map<String, dynamic>.from(snoutData.event.matches);
                  matchesWithRemoved.remove(match.key);

                  //TODO this might not be deeply modified to raw types before being applied to the patch
                  Patch patch = Patch(
                      identity: context.read<IdentityProvider>().identity,
                      time: DateTime.now(),
                      path: [
                        'matches',
                      ],
                      value: matchesWithRemoved);
                  await snoutData.addPatch(patch);
                }
              },
            ),
          ),
      ]),
    );
  }

  Future editMatch(FRCMatch match, DataProvider data, String? matchID) async {
    String? result = await Navigator.of(context).push(MaterialPageRoute(
        builder: (context) =>
            JSONEditor(source: match, validate: FRCMatch.fromJson)));

    if (result != null) {
      FRCMatch resultMatch = FRCMatch.fromJson(jsonDecode(result));
      Patch patch = Patch(
          identity: context.read<IdentityProvider>().identity,
          time: DateTime.now(),
          path: [
            'matches',
            matchID ?? resultMatch.description,
          ],
          value: resultMatch.toJson());
      await data.addPatch(patch);
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
