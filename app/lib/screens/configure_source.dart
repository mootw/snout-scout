import 'dart:convert';

import 'package:app/helpers.dart';
import 'package:app/providers/identity_provider.dart';
import 'package:app/providers/server_connection_provider.dart';
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
          const ListTile(
            title: Text("RAM Only"),
            subtitle: Text("changes are not persisted after closing"),
          ),
          Wrap(children: [
            const SizedBox(width: 8),
            OutlinedButton(
                onPressed: () async {
                  String? value = await createNewEvent(context);
                  if (value == null) {
                    return;
                  }
                  FRCEvent event = FRCEvent.fromJson(json.decode(value));
                  Patch p = Patch(
                      identity: context.read<IdentityProvider>().identity,
                      time: DateTime.now(),
                      path: Patch.buildPath([""]),
                      value: event);

                  SnoutDB newDb = SnoutDB(patches: [p]);
                },
                child: const Text("New Event")),
            const SizedBox(width: 16),
            OutlinedButton(onPressed: () {}, child: const Text("Open File")),
          ]),
          const SizedBox(height: 16),
          const Divider(),
          const ListTile(
            title: Text("Local Save"),
            subtitle: Text("changes are saved on device"),
          ),
          Wrap(children: [
            const SizedBox(width: 8),
            OutlinedButton(
                onPressed: () async {
                  String? value = await createNewEvent(context);
                  if (value == null) {
                    return;
                  }
                  FRCEvent event = FRCEvent.fromJson(json.decode(value));
                  Patch p = Patch(
                      identity: context.read<IdentityProvider>().identity,
                      time: DateTime.now(),
                      path: Patch.buildPath([""]),
                      value: event);

                  SnoutDB newDb = SnoutDB(patches: [p]);
                },
                child: const Text("New Event")),
            const SizedBox(width: 16),
            OutlinedButton(onPressed: () {}, child: const Text("Open File")),
          ]),
          const SizedBox(height: 16),
          const Divider(),
          ListTile(
            title: const Text("Server"),
            subtitle: Text(context.watch<ServerConnectionProvider>().serverURL),
            trailing: IconButton(
              icon: const Icon(Icons.miscellaneous_services_sharp),
              onPressed: () async {
                //TODO manage server page to upload, download, and delete event files.
                //TODO only display this button if the server url is set and whatnot
              },
            ),
            onTap: () async {
              final provider = context.read<ServerConnectionProvider>();
              final result = await showStringInputDialog(
                  context, "Server", provider.serverURL);
              if (result != null) {
                provider.setServer(result);
              }
            },
          ),
          const ListTile(
            leading: Icon(Icons.check, color: Colors.green),
            title: Text("2023 Regionals"),
            subtitle: Text("2023mnmi2.json"),
          ),
          const ListTile(
            title: Text("2023 State"),
            subtitle: Text("mnstate.json"),
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
