import 'dart:convert';

import 'package:app/helpers.dart';
import 'package:app/providers/identity_provider.dart';
import 'package:app/screens/edit_json.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:snout_db/event/frcevent.dart';
import 'package:snout_db/patch.dart';
import 'package:snout_db/snout_db.dart';

class ConfigureSourceScreen extends StatefulWidget {
  const ConfigureSourceScreen({super.key});

  @override
  State<ConfigureSourceScreen> createState() => _ConfigureSourceScreenState();
}

class _ConfigureSourceScreenState extends State<ConfigureSourceScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Data Selection"),
      ),
      body: ListView(
        children: [
          Wrap(children: [
            const SizedBox(width: 8),
            OutlinedButton(
                onPressed: () async {
                  String? value = await createNewEvent(context);
                  if (value == null) {
                    return;
                  }
                  FRCEvent event = FRCEvent.fromJson(jsonDecode(value));
                  Patch p = Patch(
                      identity: context.read<IdentityProvider>().identity,
                      time: DateTime.now(),
                      path: [""],
                      value: event);

                  SnoutDB newDb = SnoutDB(patches: [p]);
                },
                child: const Text("Create New Event")),
            const SizedBox(width: 16),
            OutlinedButton(onPressed: () {}, child: const Text("Open File")),
          ]),
          const Divider(),
          ListTile(
            title: const Text("Origin"),
            subtitle: const Text("https://my.server.com/"),
            leading: const Icon(Icons.check, color: Colors.green),
            trailing: IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                final result = await showStringInputDialog(
                    context, "Server", "SERVER URL");
                if (result != null && context.mounted) {
                  //TODO set server
                }
              },
            ),
          ),
          ListTile(
            title: const Text("2023 Regionals"),
            subtitle: const Text("2023mnmi2.json"),
            leading: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () {}),
          ),
          ListTile(
            title: const Text("2023 State"),
            subtitle: const Text("mnstate.json"),
            leading: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () {}),
          ),
          const ListTile(
            title: Text("Upload Event To Origin"),
            leading: Icon(Icons.upload),
          ),
        ],
      ),
    );
  }
}

Future<String?> createNewEvent(BuildContext context) async {
  return await Navigator.of(context).push(MaterialPageRoute(
      builder: (context) =>
          JSONEditor(source: emptyNewEvent, validate: FRCEvent.fromJson)));
}

FRCEvent get emptyNewEvent => FRCEvent(
    config:
        EventConfig(name: 'My Event', team: 6749, season: DateTime.now().year));
