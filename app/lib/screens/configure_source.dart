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

import 'package:http/http.dart' as http;

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
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () async {
                    TextEditingController passwordTextController =
                        TextEditingController();
                    await showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                              content: TextField(
                                controller: passwordTextController,
                                decoration: const InputDecoration(
                                    hintText: "Upload Password"),
                              ),
                              actions: [
                                TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text("Cancel")),
                                TextButton(
                                    onPressed: () async {
                                      final serverURI = context
                                          .read<DataProvider>()
                                          .serverURI;
                                      final response = await http.delete(
                                          serverURI.replace(
                                              path: "/delete_event_file"),
                                          headers: {
                                            'upload_password':
                                                passwordTextController.text,
                                            'name': event,
                                          });

                                      if (!context.mounted) {
                                        return;
                                      }

                                      if (response.statusCode == 200) {
                                        Navigator.pop(context);
                                        showDialog(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                                  title: const Text(
                                                      "Delete Success!"),
                                                  actions: [
                                                    TextButton(
                                                        onPressed: () =>
                                                            Navigator.pop(
                                                                context),
                                                        child: const Text("Ok"))
                                                  ],
                                                ));
                                      } else {
                                        showDialog(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                                  title: Text(
                                                      "Faied to delete ${response.statusCode} ${response.body}"),
                                                  actions: [
                                                    TextButton(
                                                        onPressed: () =>
                                                            Navigator.pop(
                                                                context),
                                                        child: const Text("Ok"))
                                                  ],
                                                ));
                                      }

                                      updateEvents();
                                    },
                                    child: const Text("Delete Event"))
                              ],
                            ));
                  },
                ),
              ),
          if (_eventOptions != null)
            ListTile(
              leading: const Icon(Icons.upload_file),
              title: const Text("Upload File"),
              onTap: () async {
                TextEditingController passwordTextController =
                    TextEditingController();
                await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                          content: TextField(
                            controller: passwordTextController,
                            decoration: const InputDecoration(
                                hintText: "Upload Password"),
                          ),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text("Cancel")),
                            TextButton(
                                onPressed: () async {
                                  final serverURI =
                                      context.read<DataProvider>().serverURI;
                                  const XTypeGroup typeGroup = XTypeGroup(
                                    label: 'Scouting Config',
                                    extensions: <String>['json'],
                                  );
                                  final XFile? file = await openFile(
                                      acceptedTypeGroups: <XTypeGroup>[
                                        typeGroup
                                      ]);
                                  if (!context.mounted) {
                                    return;
                                  }
                                  if (file == null) {
                                    showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                              title: const Text(
                                                  "No File Selected!"),
                                              actions: [
                                                TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(context),
                                                    child: const Text("Ok"))
                                              ],
                                            ));
                                    return;
                                  }

                                  final request = http.MultipartRequest(
                                      "POST",
                                      serverURI.replace(
                                          path: "/upload_event_file"));
                                  request.headers['upload_password'] =
                                      passwordTextController.text;
                                  request.files.add(
                                      http.MultipartFile.fromBytes(
                                          file.name, await file.readAsBytes()));
                                  final response = await request.send();
                                  if (!context.mounted) {
                                    return;
                                  }
                                  if (response.statusCode == 200) {
                                    Navigator.pop(context);
                                    showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                              title:
                                                  const Text("Upload Success!"),
                                              actions: [
                                                TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(context),
                                                    child: const Text("Ok"))
                                              ],
                                            ));
                                  } else {
                                    showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                              title: Text(
                                                  "Faied to upload ${response.statusCode}"),
                                              actions: [
                                                TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(context),
                                                    child: const Text("Ok"))
                                              ],
                                            ));
                                  }

                                  updateEvents();
                                },
                                child: const Text("Select File"))
                          ],
                        ));
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
    config: const EventConfig(name: 'Event Name', team: 6749, fieldImage: ''));
