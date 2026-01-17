import 'dart:convert';

import 'package:app/data_submit_login.dart';
import 'package:app/providers/data_provider.dart';
import 'package:app/screens/edit_json.dart';
import 'package:app/services/tba_autofill.dart';
import 'package:app/widgets/load_status_or_error_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:snout_db/action.dart';
import 'package:snout_db/actions/write_schedule.dart';
import 'package:snout_db/event/match_data.dart';
import 'package:snout_db/event/match_schedule_item.dart';

class EditSchedulePage extends StatefulWidget {
  const EditSchedulePage({super.key, required this.matches});

  final Map<String, MatchScheduleItem> matches;

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
        bottom: const LoadOrErrorStatusBar(),
        actions: [
          TextButton(
            child: const Text("AutoFill TBA"),
            onPressed: () async {
              ChainAction patch;
              try {
                patch = await loadScheduleFromTBA(snoutData.event);
              } catch (e) {
                if (context.mounted) {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text("Error Getting From TBA"),
                        content: Text(e.toString()),
                      );
                    },
                  );
                }
                return;
              }

              if (context.mounted) {
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text("data"),
                      content: SingleChildScrollView(
                        child: Text(json.encode(patch)),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () async {
                            await submitData(context, patch);
                            if (context.mounted) {
                              Navigator.pop(context);
                            }
                          },
                          child: const Text(
                            "Apply (Wait for dialog to close!)",
                          ),
                        ),
                      ],
                    );
                  },
                );
              }
            },
          ),
        ],
      ),
      body: ListView(
        children: [
          Center(
            child: FilledButton(
              onPressed: () async {
                MatchScheduleItem match = MatchScheduleItem(
                  id: "",
                  label: "",
                  scheduledTime: DateTime.now(),
                  blue: const [],
                  red: const [],
                );

                await editMatch(match, snoutData);
              },
              child: const Text('Add Match'),
            ),
          ),
          for (final match in snoutData.event.schedule.entries)
            ListTile(
              title: Text(match.value.label),
              subtitle: Text(match.key),
              onTap: () => editMatch(match.value, snoutData),
              trailing: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () async {
                  final result = await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(
                        "Are you sure you want to delete ${match.value.label}?",
                      ),
                      actions: [
                        TextButton(
                          child: const Text("No"),
                          onPressed: () => Navigator.of(context).pop(false),
                        ),
                        TextButton(
                          child: const Text("Yes"),
                          onPressed: () => Navigator.of(context).pop(true),
                        ),
                      ],
                    ),
                  );
                  if (result == true) {
                    final matchesWithRemoved =
                        Map<String, MatchScheduleItem>.from(
                          snoutData.event.schedule,
                        );
                    matchesWithRemoved.remove(match.key);

                    final action = ActionWriteSchedule(
                      matchesWithRemoved.values.toList(),
                    );
                    if (context.mounted) {
                      await submitData(context, action);
                    }
                  }
                },
              ),
            ),
        ],
      ),
    );
  }

  Future editMatch(MatchScheduleItem match, DataProvider data) async {
    String? result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            JSONEditor(source: match, validate: MatchScheduleItem.fromJson),
      ),
    );

    if (result != null && mounted) {
      MatchScheduleItem resultMatch = MatchScheduleItem.fromJson(
        json.decode(result),
      );

      final schedule = context.read<DataProvider>().event.schedule;
      final action = ActionWriteSchedule([...schedule.values, resultMatch]);
      if (mounted && context.mounted) {
        await submitData(context, action);
      }
    }
  }
}

//Details about the match like its scheduled time, level, description.
class EditMatchDetails extends StatefulWidget {
  const EditMatchDetails({super.key, required this.match});

  final MatchData match;

  @override
  State<EditMatchDetails> createState() => EditMatchDetailsState();
}

class EditMatchDetailsState extends State<EditMatchDetails> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Match'),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(widget.match);
          },
          child: const Text("Save"),
        ),
      ],
    );
  }
}
