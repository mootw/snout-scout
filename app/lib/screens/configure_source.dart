import 'dart:convert';

import 'package:app/style.dart';
import 'package:app/providers/data_provider.dart';
import 'package:app/providers/identity_provider.dart';
import 'package:app/providers/loading_status_service.dart';
import 'package:app/screens/edit_json.dart';
import 'package:app/widgets/load_status_or_error_bar.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
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
  List<String>? _eventOptions;

  @override
  void initState() {
    super.initState();

    updateEvents();
  }

  void updateEvents() async {
    setState(() {
      //Show the loading indicator (avoid stale data on server switch)
      _eventOptions = null;
    });
    try {
      final result = await context.read<DataProvider>().getEventList();
      setState(() {
        _eventOptions = result;
      });
    } catch (e, s) {
      Logger.root.severe("Failed to load server event list", e, s);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Data Selection"),
        bottom: const LoadOrErrorStatusBar(),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: data.dataSource != DataSource.memory
                ? null
                : const Icon(Icons.check, color: Colors.green),
            title: const Text("RAM Only"),
            subtitle:
                const Text("does not clear open db. changes are not persisted"),
            onTap: () => data.setDataSource(DataSource.memory),
          ),
          const Divider(),
          ListTile(
            leading: data.dataSource != DataSource.localDisk
                ? null
                : const Icon(Icons.check, color: Colors.green),
            title: const Text("Local Save"),
            subtitle: const Text("changes are saved on device"),
            onTap: () => data.setDataSource(DataSource.localDisk),
          ),
          Wrap(children: [
            const SizedBox(width: 8),
            OutlinedButton(
                onPressed: () async {
                  final identity = context.read<IdentityProvider>().identity;
                  final value = await createNewEvent(context);
                  if (value == null) {
                    return;
                  }
                  FRCEvent event = FRCEvent.fromJson(json.decode(value));
                  Patch p = Patch(
                      identity: identity,
                      time: DateTime.now(),
                      path: Patch.buildPath([""]),
                      value: event.toJson());

                  await data.writeLocalDiskDatabase(SnoutDB(patches: [p]));
                  await data.setDataSource(DataSource.localDisk);
                },
                child: const Text("New Event")),
            const SizedBox(width: 16),
            OutlinedButton(
                onPressed: () async {
                  final future = () async {
                    try {
                      const XTypeGroup typeGroup = XTypeGroup(
                        label: 'Snout DB JSON',
                        extensions: <String>['json'],
                      );
                      final XFile? file = await openFile(
                          acceptedTypeGroups: <XTypeGroup>[typeGroup]);

                      if (file == null) {
                        return;
                      }

                      final fileString = await file.readAsString();

                      await data.writeLocalDiskDatabase(
                          SnoutDB.fromJson(json.decode(fileString)));
                      await data.setDataSource(DataSource.localDisk);
                    } catch (e, s) {
                      Logger.root.severe("Failed to load new file", e, s);
                    }
                  }();
                  loadingService.addFuture(future);
                  return await future;
                },
                child: const Text("Replace with DB File")),
          ]),
          const SizedBox(height: 16),
          const Divider(),
          ListTile(
            leading: data.dataSource != DataSource.remoteServer
                ? null
                : const Icon(Icons.check),
            title: const Text("Server"),
            subtitle: Text(context.watch<DataProvider>().serverURL),
            onTap: () async {
              final provider = context.read<DataProvider>();
              final result = await showStringInputDialog(
                  context, "Server", provider.serverURL);
              if (result != null) {
                await provider.setServer(result);
              }
              updateEvents();
            },
          ),
          if (_eventOptions == null)
            const Center(child: CircularProgressIndicator()),
          if (_eventOptions != null)
            for (var event in _eventOptions!)
              ListTile(
                leading: data.dataSource == DataSource.remoteServer &&
                        context.watch<DataProvider>().selectedEvent == event
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                title: Text(event),
                onTap: () async {
                  await context.read<DataProvider>().setSelectedEvent(event);
                  data.setDataSource(DataSource.remoteServer);
                },
              ),
          if (_eventOptions != null)
            ListTile(
              leading: const Icon(Icons.miscellaneous_services_sharp),
              title: const Text("Manage Server (TODO NOT IMPLEMENTED)"),
              onTap: () async {
                //TODO manage server page to upload, download, and delete event files.
                //TODO only display this button if the server url is set and whatnot
              },
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
    config: EventConfig(name: '', team: 6749, season: DateTime.now().year));
