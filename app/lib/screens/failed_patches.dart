import 'dart:convert';

import 'package:app/providers/data_provider.dart';
import 'package:app/widgets/load_status_or_error_bar.dart';
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
    final serverConnection = context.watch<DataProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text("Outbox"),
        bottom: const LoadOrErrorStatusBar(),
        actions: [
          if (serverConnection.remoteOutbox.commitLock.locked == false)
            IconButton(
              onPressed: () async {
                await serverConnection.remoteOutbox.commitPatchs();
                setState(() {});
              },
              icon: Icon(Icons.send),
            ),
          IconButton(
            color: Colors.red,
            onPressed:
                () => showDialog(
                  context: context,
                  builder:
                      (context) => AlertDialog(
                        title: const Text(
                          "Are you sure you want to delete ALL failed transactions?",
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Cancel"),
                          ),
                          FilledButton.tonal(
                            style: FilledButton.styleFrom(
                              backgroundColor:
                                  Theme.of(context).colorScheme.errorContainer,
                            ),
                            onPressed: () async {
                              await serverConnection.remoteOutbox.clearOutbox();
                              setState(() {});
                              if (context.mounted) {
                                Navigator.pop(context);
                              }
                            },
                            child: const Text("Delete"),
                          ),
                        ],
                      ),
                ),
            icon: const Icon(Icons.delete),
          ),
        ],
      ),
      body: ListView(
        children: [
          for (final patch in serverConnection.remoteOutbox.outboxCache)
            ListTile(
              onTap:
                  () => showDialog(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          title: const Text("Patch Data"),
                          content: SelectableText(patch),
                        ),
                  ),
              title: Text(
                DateFormat.yMMMMEEEEd().add_Hms().format(
                  Patch.fromJson(json.decode(patch)).time,
                ),
              ),
              subtitle: Text(
                Patch.fromJson(json.decode(patch)).path.toString(),
              ),
            ),
        ],
      ),
    );
  }
}
