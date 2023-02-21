


import 'dart:convert';

import 'package:app/main.dart';
import 'package:flutter/material.dart';
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
      ),
      body: ListView(
        children: [
          const Text("Failed Patches"),
          for(final patch in snoutData.failedPatches)
            ListTile(
              onTap: () => showDialog(context: context, builder: (context) => AlertDialog(
                title: const Text("Patch Data"),
                content: SelectableText(patch),
              )),
              tileColor: Colors.red,
              title: Text(Patch.fromJson(jsonDecode(patch)).time.toIso8601String()),
              subtitle: Text(Patch.fromJson(jsonDecode(patch)).path.toString()),
              trailing: IconButton(onPressed: () async {
                  await snoutData.addPatch(Patch.fromJson(jsonDecode(patch)));
                }, icon: const Icon(Icons.refresh)),
            ),
          const Text("Successful Patches"),
          for(final patch in snoutData.successfulPatches)
            ListTile(
              onTap: () => showDialog(context: context, builder: (context) => AlertDialog(
                title: const Text("Patch Data"),
                content: SelectableText(patch),
              )),
              tileColor: Colors.green,
              title: Text(Patch.fromJson(jsonDecode(patch)).time.toIso8601String()),
              subtitle: Text(Patch.fromJson(jsonDecode(patch)).path.toString()),
              
            ),

        ],
      ),
    );
  }
}