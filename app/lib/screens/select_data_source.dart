import 'dart:convert';

import 'package:app/config_editor/config_editor.dart';
import 'package:app/main.dart';
import 'package:app/mock_data_generator.dart';
import 'package:app/providers/data_provider.dart';
import 'package:app/screens/scout_authenticator_dialog.dart';
import 'package:app/services/data_service.dart';
import 'package:app/style.dart';
import 'package:app/providers/loading_status_service.dart';
import 'package:app/screens/edit_json.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:share_plus/share_plus.dart';
import 'package:snout_db/action.dart';
import 'package:snout_db/actions/write_config.dart';
import 'package:snout_db/event/frcevent.dart';
import 'package:snout_db/snout_chain.dart';

import 'package:http/http.dart' as http;

class SelectDataSourceScreen extends StatefulWidget {
  const SelectDataSourceScreen({super.key});

  @override
  State<SelectDataSourceScreen> createState() => _SelectDataSourceScreenState();
}

class _SelectDataSourceScreenState extends State<SelectDataSourceScreen> {
  List<String> _localDatabases = [];

  List<(String uri, String path)> _previousServers = [];

  @override
  void initState() {
    super.initState();
    updateLocalDbs();
    updateServerList();
  }

  Future updateServerList() async {
    final items = <(String uri, String path)>[];
    if (await remoteDBPath.exists() == false) {
      return;
    }
    await for (final item in remoteDBPath.list()) {
      items.add((
        Uri.decodeFull(utf8.decode(base64Decode(item.path.split('/').last))),
        item.path,
      ));
    }
    if (context.mounted) {
      setState(() {
        _previousServers = items;
      });
    }
  }

  Future updateLocalDbs() async {
    final items = <String>[];
    if (await localSnoutDBPath.exists() == false) {
      return;
    }
    await for (final item in localSnoutDBPath.list()) {
      items.add(item.path);
    }
    if (context.mounted) {
      setState(() {
        _localDatabases = items;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Data Selection")),
      body: ListView(
        children: [
          /// DEMO Data (generate mocked data?! could use real randomized data)
          ListTile(
            leading: const Icon(Icons.phone_android),
            title: const Text("DEMO"),
            subtitle: const Text("Loads demo data!"),
            onTap: () async {
              final sourceUri = Uri.parse(
                '${localSnoutDBPath.path}/sample.snoutdb',
              );
              final mockData = await generateMockData(seed: 1);
              await writeLocalDiskDatabase(
                SnoutDBFile(actions: mockData),
                sourceUri,
              );
              updateLocalDbs();
            },
          ),
          ListTile(
            leading: const Icon(Icons.create_new_folder),
            title: const Text("New Database"),
            onTap: () async {
              final evergreenField = await rootBundle.load(
                'evergreen_field.avif',
              );
              if (context.mounted) {
                final EventConfig? value = await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ConfigEditorPage(
                      initialState: EventConfig(
                        name: '',
                        team: 6749,
                        fieldImage: base64Encode(
                          evergreenField.buffer.asUint8List(),
                        ),
                      ),
                    ),
                  ),
                );

                if (value == null) {
                  return;
                }

                // Login
                final RegistrationResult? login =
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ScoutRegistrationScreen(),
                      ),
                    );

                if (login == null) {
                  return;
                }

                if (context.mounted) {
                  FRCEvent event = FRCEvent(config: value, matches: {});

                  final sourceUri = Uri.parse(
                    '${localSnoutDBPath.path}/${event.config.name}.snoutdb',
                  );
                  final loginMessage = await ChainActionData(
                    time: DateTime.now(),
                    previousHash: Uint8List(32),
                    action: login.$2,
                  ).encodeAndSign(login.$1);
                  await writeLocalDiskDatabase(
                    SnoutDBFile(
                      actions: [
                        loginMessage,
                        await ChainActionData(
                          time: DateTime.now(),
                          previousHash: await loginMessage.hash,
                          action: ActionWriteConfig(event.config),
                        ).encodeAndSign(login.$1),
                      ],
                    ),
                    sourceUri,
                  );

                  if (context.mounted) {
                    await SnoutScoutApp.getState(context)?.setSource(sourceUri);
                    if (context.mounted && Navigator.canPop(context)) {
                      Navigator.pop(context, sourceUri);
                    }
                  }
                }
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.create_new_folder),
            title: const Text("New Database (Raw)"),
            onTap: () async {
              if (context.mounted) {
                final value = await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => JSONEditor(
                      source: emptyNewEvent,
                      validate: FRCEvent.fromJson,
                    ),
                  ),
                );
                if (value == null) {
                  return;
                }

                // Login
                final RegistrationResult? login =
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ScoutRegistrationScreen(),
                      ),
                    );

                if (login == null) {
                  return;
                }

                if (context.mounted) {
                  FRCEvent event = FRCEvent.fromJson(json.decode(value));

                  final sourceUri = Uri.parse(
                    '${localSnoutDBPath.path}/${event.config.name}.snoutdb',
                  );
                  final loginMessage = await ChainActionData(
                    time: DateTime.now(),
                    previousHash: Uint8List(32),
                    action: login.$2,
                  ).encodeAndSign(login.$1);
                  await writeLocalDiskDatabase(
                    SnoutDBFile(
                      actions: [
                        loginMessage,
                        await ChainActionData(
                          time: DateTime.now(),
                          previousHash: await loginMessage.hash,
                          action: ActionWriteConfig(event.config),
                        ).encodeAndSign(login.$1),
                      ],
                    ),
                    sourceUri,
                  );

                  if (context.mounted) {
                    await SnoutScoutApp.getState(context)?.setSource(sourceUri);
                    if (context.mounted && Navigator.canPop(context)) {
                      Navigator.pop(context, sourceUri);
                    }
                  }
                }
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.file_open),
            title: const Text("Load From Device"),
            subtitle: const Text(
              "It will override any local databases with the same name.",
            ),
            onTap: () async {
              final future = () async {
                try {
                  const XTypeGroup typeGroup = XTypeGroup(
                    label: 'Snout DB',
                    extensions: ['snoutdb'],
                  );
                  final XFile? selectedFile = await openFile(
                    acceptedTypeGroups: <XTypeGroup>[typeGroup],
                  );

                  if (selectedFile == null) {
                    return;
                  }

                  final fileContent = await selectedFile.readAsBytes();

                  final localFile = fs.file(
                    '${localSnoutDBPath.path}/${selectedFile.name}',
                  );
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
                kDebugMode ? 'http://127.0.0.1:6749' : 'https://myserver.com',
              );

              if (context.mounted && result != null) {
                final eventFile = await Navigator.push<Uri>(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        SnoutServerPage(serverUri: Uri.parse(result)),
                  ),
                );

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

          const ListTile(title: Text('Databases')),

          for (final item in _localDatabases)
            ListTile(
              title: Text(item),
              onTap: () async {
                await SnoutScoutApp.getState(
                  context,
                )?.setSource(Uri.parse(item));
                if (context.mounted && Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              },
              trailing: IconButton(
                onPressed: () async {
                  await fs.file(item).delete();
                  updateLocalDbs();
                },
                icon: const Icon(Icons.delete),
              ),
            ),

          // The servers and local implementations are different due to how
          // the data is handled right now
          for (final item in _previousServers)
            ListTile(
              title: Text(item.$1),
              leading: IconButton(
                onPressed: () => SharePlus.instance.share(
                  ShareParams(
                    text:
                        'https://snout-scout.web.app/#/${Uri.encodeComponent(item.$1)}',
                  ),
                ),
                icon: const Icon(Icons.share),
              ),
              onTap: () async {
                await SnoutScoutApp.getState(
                  context,
                )?.setSource(Uri.parse(item.$1));
                if (context.mounted && Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              },
              trailing: IconButton(
                onPressed: () async {
                  await fs.file(item.$2).delete();
                  updateServerList();
                },
                icon: const Icon(Icons.delete),
              ),
            ),
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
      if (mounted) {
        setState(() {
          _eventOptions = res;
        });
      }
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
            onPressed: () => updateEvents(),
            icon: const Icon(Icons.refresh),
          ),
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
                            hintText: "Upload Password",
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Cancel"),
                          ),
                          TextButton(
                            onPressed: () async {
                              final response = await http.delete(
                                getEventPath(event),
                                headers: {
                                  'upload_password':
                                      passwordTextController.text,
                                },
                              );

                              if (!context.mounted) {
                                return;
                              }

                              if (response.statusCode == 200) {
                                Navigator.pop(context);
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text("Delete Success!"),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text("Ok"),
                                      ),
                                    ],
                                  ),
                                );
                              } else {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text(
                                      "Faied to delete ${response.statusCode} ${response.body}",
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text("Ok"),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              updateEvents();
                            },
                            child: const Text("Delete Event"),
                          ),
                        ],
                      ),
                    );
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
                        hintText: "Upload Password",
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Cancel"),
                      ),
                      TextButton(
                        onPressed: () async {
                          const XTypeGroup typeGroup = XTypeGroup(
                            label: 'Snout DB',
                            extensions: <String>['snoutdb'],
                          );
                          final XFile? file = await openFile(
                            acceptedTypeGroups: <XTypeGroup>[typeGroup],
                          );
                          if (!context.mounted) {
                            return;
                          }
                          if (file == null) {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text("No File Selected!"),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text("Ok"),
                                  ),
                                ],
                              ),
                            );
                            return;
                          }

                          final request = http.MultipartRequest(
                            "PUT",
                            widget.serverUri.replace(path: "/upload_events"),
                          );
                          request.headers['upload_password'] =
                              passwordTextController.text;
                          request.files.add(
                            http.MultipartFile.fromBytes(
                              file.name,
                              await file.readAsBytes(),
                            ),
                          );
                          final response = await request.send();
                          if (!context.mounted) {
                            return;
                          }
                          if (response.statusCode == 200) {
                            Navigator.pop(context);
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text("Upload Success!"),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text("Ok"),
                                  ),
                                ],
                              ),
                            );
                          } else {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text(
                                  "Faied to upload ${response.statusCode}",
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text("Ok"),
                                  ),
                                ],
                              ),
                            );
                          }

                          updateEvents();
                        },
                        child: const Text("Select File"),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

FRCEvent get emptyNewEvent => FRCEvent(
  matches: {},
  config: const EventConfig(name: 'Event Name', team: 6749, fieldImage: ''),
);
