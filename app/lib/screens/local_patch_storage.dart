import 'dart:convert';

import 'package:app/eventdb_state.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:snout_db/patch.dart';

class LocalPatchStorage extends StatefulWidget {
  const LocalPatchStorage({super.key});

  @override
  State<LocalPatchStorage> createState() => _LocalPatchStorageState();
}

class _LocalPatchStorageState extends State<LocalPatchStorage> {
  @override
  Widget build(BuildContext context) {
    final snoutData = context.watch<EventDB>();
    return Scaffold(
      appBar: AppBar(
        title: const Text("Local Patch Storage"),
        actions: [
          IconButton(
              color: Colors.red,
              onPressed: () => showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                        title: const Text(
                            "Are you sure you want to delete ALL failed patches?"),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text("Cancel")),
                          FilledButton.tonal(
                              style: FilledButton.styleFrom(
                                  backgroundColor: Theme.of(context)
                                      .colorScheme
                                      .errorContainer),
                              onPressed: () async {
                                await snoutData.clearFailedPatches();
                                if (mounted) {
                                  Navigator.pop(context);
                                }
                              },
                              child: const Text("Delete")),
                        ],
                      )),
              icon: const Icon(Icons.delete)),
          IconButton(
              color: Colors.green,
              onPressed: () => showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                        title: const Text(
                            "Are you sure you want to delete ALL successful patches?"),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text("Cancel")),
                          FilledButton.tonal(
                              style: FilledButton.styleFrom(
                                  backgroundColor: Theme.of(context)
                                      .colorScheme
                                      .errorContainer),
                              onPressed: () async {
                                await snoutData.clearSuccessfulPatches();
                                if (mounted) {
                                  Navigator.pop(context);
                                }
                              },
                              child: const Text("Delete")),
                        ],
                      )),
              icon: const Icon(Icons.delete)),
        ],
      ),
      body: ListView(
        children: [
          const Center(child: Text("Failed Patches")),
          for (final patch in snoutData.failedPatches.reversed)
            ListTile(
              onTap: () => showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                        title: const Text("Patch Data"),
                        content: SelectableText(patch),
                      )),
              tileColor: Colors.red,
              title: Text(DateFormat.yMMMMEEEEd()
                  .add_Hms()
                  .format(Patch.fromJson(jsonDecode(patch)).time)),
              subtitle: Text(Patch.fromJson(jsonDecode(patch)).path.toString()),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                      onPressed: () async {
                        await snoutData
                            .addPatch(Patch.fromJson(jsonDecode(patch)));
                        setState(() {});
                      },
                      icon: const Icon(Icons.refresh)),
                ],
              ),
            ),
          const Center(child: Text("Successful Patches")),
          for (final patch in snoutData.successfulPatches.reversed)
            ListTile(
              onTap: () => showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                        title: const Text("Patch Data"),
                        content: SelectableText(patch),
                      )),
              tileColor: Colors.green,
              title: Text(DateFormat.yMMMMEEEEd()
                  .add_Hms()
                  .format(Patch.fromJson(jsonDecode(patch)).time)),
              subtitle: Text(Patch.fromJson(jsonDecode(patch)).path.toString()),
            ),
        ],
      ),
    );
  }
}
