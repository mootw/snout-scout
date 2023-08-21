import 'dart:async';
import 'dart:convert';

import 'package:app/providers/data_provider.dart';
import 'package:app/helpers.dart';
import 'package:app/providers/server_connection_provider.dart';
import 'package:app/screens/analysis.dart';
import 'package:app/screens/debug_field_position.dart';
import 'package:app/screens/edit_json.dart';
import 'package:app/screens/local_patch_storage.dart';
import 'package:app/screens/schedule_page.dart';
import 'package:app/screens/teams_page.dart';
import 'package:app/search.dart';
import 'package:download/download.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import 'package:snout_db/config/eventconfig.dart';
import 'package:snout_db/patch.dart';
import 'package:snout_db/snout_db.dart';
import 'package:url_launcher/url_launcher_string.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Logger.root.onRecord.listen((record) {
    // For now logging will always print to console,
    // since the app is open source we're ok with that..
    // at some point it might make sense to actually write
    // these logs to a file so they can be pulled later!
    // ignore: avoid_print
    print('${record.level.name}: ${record.time}: ${record.message}');
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
        providers: [
          ChangeNotifierProvider<DataProvider>(create: (_) => DataProvider()),
          ChangeNotifierProvider<ServerConnectionProvider>(create: (_) => ServerConnectionProvider()),
        ],
        child: MaterialApp(
          title: 'Snout Scout',
          theme: defaultTheme,
          home: const MyHomePage(),
        ));
  }
}



class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _currentPageIndex = 0;

  PreferredSize? getErrorBar() {
    final data = context.read<ServerConnectionProvider>();

    if (data.failedPatches.isNotEmpty) {
      return PreferredSize(
        preferredSize: const Size.fromHeight(36),
        child: InkWell(
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const LocalPatchStorage(),
              )),
          child: Container(
              alignment: Alignment.center,
              width: double.infinity,
              height: 36,
              color: Colors.orange,
              child: Text(
                  "You have ${data.failedPatches.length} failed patches! Tap to see")),
        ),
      );
    }

    if (data.connected == false) {
      return PreferredSize(
        preferredSize: const Size.fromHeight(36),
        child: Container(
            alignment: Alignment.center,
            width: double.infinity,
            height: 36,
            color: Theme.of(context).colorScheme.errorContainer,
            child: const Text("No Live Connection to server!!!")),
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final serverConnection = context.watch<ServerConnectionProvider>();
    String? tbaKey = context.watch<DataProvider>().db.config.tbaEventId;

    return Scaffold(
      appBar: AppBar(
        bottom: getErrorBar(),
        titleSpacing: 0,
        title: Text(data.db.config.name),
        actions: [
          if (tbaKey != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilledButton.tonal(
                  onPressed: () => launchUrlString(
                      "https://www.thebluealliance.com/event/$tbaKey#rankings"),
                  child: const Text("Rankings")),
            ),
          IconButton(
              onPressed: () =>
                  showSearch(context: context, delegate: SnoutScoutSearch()),
              icon: const Icon(Icons.search))
        ],
      ),
      body: [
        const AllMatchesPage(),
        const TeamGridList(),
        const AnalysisPage(),
      ][_currentPageIndex],
      drawer: Drawer(
        child: ListView(children: [
          ListTile(
            title: const Text("Server"),
            subtitle: Text(serverConnection.serverURL),
            trailing: IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                final result = await showStringInputDialog(
                    context, "Server", serverConnection.serverURL);
                if (result != null && context.mounted) {
                  await serverConnection.setServer(result);
                }
              },
            ),
          ),
          ListTile(
            title: const Text("Last Origin Sync"),
            subtitle: serverConnection.lastOriginSync == null
                ? const Text("Never")
                : Text(DateFormat.yMMMMEEEEd()
                    .add_Hms()
                    .format(serverConnection.lastOriginSync!)),
          ),
          ListTile(
            title: const Text("Local Patch Storage"),
            trailing: const Icon(Icons.data_object),
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LocalPatchStorage(),
                  ));
            },
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: FilledButton(
                  onPressed: () {
                    final data = context.read<DataProvider>().db;
                    final stream =
                        Stream.fromIterable(utf8.encode(jsonEncode(data)));
                    download(stream, '${data.config.name}.json');
                  },
                  child: const Text("Download Event Data to File")),
            ),
          ),
          const Divider(),
          ListTile(
            title: const Text("Event Config"),
            subtitle: Text(data.db.config.name),
            trailing: IconButton(
                onPressed: () async {
                  final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => JSONEditor(
                          validate: EventConfig.fromJson,
                          source: context.read<DataProvider>().db.config,
                        ),
                      ));

                  if (result != null) {
                    Patch patch = Patch(
                        time: DateTime.now(), path: ['config'], data: result);
                    //Save the scouting results to the server!!
                    await data.addPatch(patch);
                  }
                },
                icon: const Icon(Icons.edit)),
          ),
          const Divider(),
          ListTile(
            title: const Text("Read DOCS"),
            trailing: const Icon(Icons.menu_book),
            onTap: () => launchUrlString(
                "https://github.com/mootw/snout-scout/blob/main/readme.md"),
          ),
          ListTile(
            title: const Text("DEBUG Field position"),
            trailing: const Icon(Icons.crop_square_sharp),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const DebugFieldPosition()),
              );
            },
          ),
        ]),
      ),
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (int index) {
          setState(() {
            _currentPageIndex = index;
          });
        },
        selectedIndex: _currentPageIndex,
        destinations: const [
          NavigationDestination(
            selectedIcon: Icon(Icons.table_rows),
            icon: Icon(Icons.table_rows_outlined),
            label: 'Schedule',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.people),
            icon: Icon(Icons.people_alt_outlined),
            label: 'Teams',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.analytics),
            icon: Icon(Icons.analytics_outlined),
            label: 'Analysis',
          ),
        ],
      ),
    );
  }
}
