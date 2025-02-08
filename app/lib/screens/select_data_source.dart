import 'dart:convert';

import 'package:app/main.dart';
import 'package:app/services/data_service.dart';
import 'package:app/style.dart';
import 'package:app/providers/identity_provider.dart';
import 'package:app/providers/loading_status_service.dart';
import 'package:app/screens/edit_json.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import 'package:snout_db/event/frcevent.dart';
import 'package:snout_db/patch.dart';
import 'package:snout_db/snout_db.dart';

import 'package:http/http.dart' as http;

class SelectDataSourceScreen extends StatefulWidget {
  const SelectDataSourceScreen({super.key});

  @override
  State<SelectDataSourceScreen> createState() => _SelectDataSourceScreenState();
}

class _SelectDataSourceScreenState extends State<SelectDataSourceScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Data Selection"),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.phone_android),
            title: const Text("DEMO"),
            subtitle: const Text("Loads demo data!"),
            onTap: () => {},
          ),

          ListTile(
            leading: const Icon(Icons.create_new_folder),
            title: const Text("Disk: New Database"),
            subtitle: const Text("Create a new local database"),
            onTap: () async {
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

              event.toJson();

              final dbText = json.encode(SnoutDB(patches: [p])
                  .patches
                  .map((e) => e.toJson())
                  .toList());

              final fileContent = utf8.encode(dbText);

              final localFile = fs.file(
                  '${localSnoutDBPath.path}/${event.config.name}.snoutdb');
              if (await localFile.exists() == false) {
                await localFile.create(recursive: true);
              }
              await localFile.writeAsBytes(fileContent, flush: true);
              final sourceUri = Uri.parse(localFile.path);

              if (context.mounted) {
                await SnoutScoutApp.getState(context)?.setSource(sourceUri);
                if (context.mounted && Navigator.canPop(context)) {
                  Navigator.pop(context, sourceUri);
                }
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.file_open),
            title: const Text("Disk: Upload Database"),
            subtitle: const Text(
                "Upload a database from your device. It will override any local databases with the same name."),
            onTap: () async {
              final future = () async {
                try {
                  const XTypeGroup typeGroup = XTypeGroup(
                    label: 'Snout DB JSON',
                    extensions: <String>['json'],
                  );
                  final XFile? selectedFile = await openFile(
                      acceptedTypeGroups: <XTypeGroup>[typeGroup]);

                  if (selectedFile == null) {
                    return;
                  }

                  final fileContent = await selectedFile.readAsBytes();

                  final localFile =
                      fs.file('${localSnoutDBPath.path}/${selectedFile.name}');
                  if (await localFile.exists() == false) {
                    await localFile.create(recursive: true);
                  }
                  await localFile.writeAsBytes(fileContent, flush: true);
                  final sourceUri = Uri.parse(localFile.path);

                  if (context.mounted) {
                    await SnoutScoutApp.getState(context)?.setSource(sourceUri);
                    if (context.mounted && Navigator.canPop(context)) {
                      Navigator.pop(context);
                    }
                  }
                } catch (e, s) {
                  Logger.root.severe("Failed to load new file", e, s);
                }
              }();
              loadingService.addFuture(future);
              return await future;
            },
          ),

          ListTile(
            leading: const Icon(Icons.dns),
            title: const Text("Server"),
            subtitle: const Text("Connect to remote server"),
            onTap: () async {
              final result = await showStringInputDialog(
                  context,
                  "Server",
                  kDebugMode
                      ? 'http://127.0.0.1:6749'
                      : 'https://myserver.com');

              if (context.mounted && result != null) {
                final eventFile = await Navigator.push<Uri>(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            SnoutServerPage(serverUri: Uri.parse(result))));

                if (context.mounted && eventFile != null) {
                  await SnoutScoutApp.getState(context)?.setSource(eventFile);
                  if (context.mounted && Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
                }
              }
            },
          ),
          const Divider(),

          /// DEMO Data (generate mocked data?! could use real randomized data)
          /// Local Disk
          ///   - New Database (Prompt to select location, and initial Scout ID)
          ///   - Open Existing Database
          /// Server
          ///   - Prompts to connect to server
          ///
          /// Recently Used ??

          /// Each "DataStore" is a string containing:
          /// - Connection type (server, disk, memory?)
          /// - URI (either server URI or file path)
          /// URI is used to encode the storage location of all related resources (probably hash?)
          ///   - Database file itself (which contains some media)
          ///   - any cached items
          ///   - list of all published and failed patches

          // const ListTile(
          //   title: Text('Recently Used'),
          // ),
          // // ListTile(
          // //   autofocus: true,
          // //   leading: const Icon(Icons.refresh),
          // //   title: const Text("Use Currently Selected"),
          // //   subtitle: const Text(
          // //       "Insert uri here https://scout.xqkz.net/events/WeekZero.snoutdb"),
          // //   onTap: () => {},
          // // ),
          // ListTile(
          //   title: Text('https://scout.xqkz.net'),
          //   subtitle: Text('Server'),
          //   trailing: Icon(Icons.delete),
          // ),
          // ListTile(
          //   title: Text('WeekZero'),
          //   subtitle: Text('file://storage/lol/directory/WeekZero.snoutdb'),
          //   trailing: Icon(Icons.delete),
          // ),
        ],
      ),
    );
  }
}

/// Connects to a snout scout server. Lists the events, and also has the management functions
class SnoutServerPage extends StatefulWidget {
  final Uri serverUri;

  const SnoutServerPage({required this.serverUri, super.key});

  @override
  State<SnoutServerPage> createState() => _SnoutServerPageState();
}

class _SnoutServerPageState extends State<SnoutServerPage> {
  List<String>? _eventOptions;

  bool _loading = false;

  //Root path for the selected event
  Uri getEventPath(String selectedEvent) =>
      widget.serverUri.resolve("/events/$selectedEvent");

  void updateEvents() async {
    try {
      final url = widget.serverUri.resolve("/events");
      setState(() {
        _eventOptions = [];
        _loading = true;
      });
      final result = http.get(url);
      result.whenComplete(() {
        if (mounted) {
          setState(() {
            _loading = false;
          });
        }
      });

      final res = List<String>.from(json.decode((await result).body));
      setState(() {
        _eventOptions = res;
      });
    } catch (e, s) {
      Logger.root.severe("Failed to load server event list", e, s);
    }
  }

  @override
  void initState() {
    super.initState();
    updateEvents();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.serverUri.toString()),
        actions: [
          IconButton(
              onPressed: () => updateEvents(), icon: const Icon(Icons.refresh)),
        ],
      ),
      body: ListView(
        children: [
          if (_loading) const Center(child: CircularProgressIndicator()),
          if (_eventOptions != null)
            for (var event in _eventOptions!)
              ListTile(
                title: Text(event),
                onTap: () => Navigator.pop(context, getEventPath(event)),
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
                                      final response = await http.delete(
                                          widget.serverUri.replace(
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
                                      widget.serverUri
                                          .replace(path: "/upload_event_file"));
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
