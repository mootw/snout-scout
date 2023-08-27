import 'dart:convert';

import 'package:app/providers/data_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:snout_db/patch.dart';

class FailedPatchStorage extends StatefulWidget {
  const FailedPatchStorage({super.key});

  @override
  State<FailedPatchStorage> createState() => _FailedPatchStorageState();
}

class _FailedPatchStorageState extends State<FailedPatchStorage> {
  @override
  Widget build(BuildContext context) {
    final snoutData = context.watch<DataProvider>();
    final serverConnection = context.watch<DataProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text("Failed Patches"),
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
                                await serverConnection.clearFailedPatches();
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
          for (final patch in serverConnection.failedPatches.reversed)
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
                  .format(Patch.fromJson(json.decode(patch)).time)),
              subtitle: Text(Patch.fromJson(json.decode(patch)).path.toString()),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                      onPressed: () async {
                        //wtf is this
                        await snoutData
                            .submitPatch(Patch.fromJson(json.decode(patch)));
                        setState(() {});
                      },
                      icon: const Icon(Icons.refresh)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
