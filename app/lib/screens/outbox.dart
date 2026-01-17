import 'dart:convert';

import 'package:app/providers/data_provider.dart';
import 'package:app/widgets/load_status_or_error_bar.dart';
import 'package:cbor/cbor.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:snout_db/message.dart';

class OutboxStoragePage extends StatefulWidget {
  const OutboxStoragePage({super.key});

  @override
  State<OutboxStoragePage> createState() => _OutboxStoragePageState();
}

class _OutboxStoragePageState extends State<OutboxStoragePage> {
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
                await serverConnection.remoteOutbox.commitActions();
                setState(() {});
              },
              icon: Icon(Icons.send),
            ),
          IconButton(
            color: Colors.red,
            onPressed: () => showDialog(
              context: context,
              builder: (context) => AlertDialog(
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
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.errorContainer,
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
              onTap: () => showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Patch Data"),
                  content: Text(
                    SignedChainMessage.fromCbor(
                      cbor.decode(base64Decode(patch)) as CborMap,
                    ).payload.action.toCbor().toString(),
                  ),
                ),
              ),
              leading: IconButton(
                icon: Icon(Icons.delete),
                onPressed: () {
                  serverConnection.remoteOutbox.remove(patch);
                },
              ),
              title: Text(
                DateFormat.yMMMMEEEEd().add_Hms().format(
                  SignedChainMessage.fromCbor(
                    cbor.decode(base64Decode(patch)) as CborMap,
                  ).payload.time,
                ),
              ),
              subtitle: Text(
                SignedChainMessage.fromCbor(
                  cbor.decode(base64Decode(patch)) as CborMap,
                ).payload.action.toString(),
              ),
            ),
        ],
      ),
    );
  }
}
