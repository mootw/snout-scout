import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:app/providers/data_provider.dart';
import 'package:app/helpers.dart';
import 'package:app/providers/identity_provider.dart';
import 'package:app/screens/analysis.dart';
import 'package:app/screens/configure_source.dart';
import 'package:app/screens/documentation_page.dart';
import 'package:app/screens/edit_json.dart';
import 'package:app/screens/failed_patches.dart';
import 'package:app/screens/patch_history.dart';
import 'package:app/screens/schedule_page.dart';
import 'package:app/screens/scout_leaderboard.dart';
import 'package:app/screens/teams_page.dart';
import 'package:app/search.dart';
import 'package:download/download.dart';
import 'package:flutter/material.dart';
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
    print(
        '${record.level.name}: ${record.time}: ${record.message}\n${record.error}\n${record.stackTrace}');
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
        providers: [
          ChangeNotifierProvider<IdentityProvider>(
              create: (_) => IdentityProvider()),
          ChangeNotifierProvider<DataProvider>(create: (_) => DataProvider()),
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

  @override
  void initState() {
    super.initState();
    Logger.root.onRecord.listen((record) {
      if (record.level >= Level.SEVERE) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(record.message),
          duration: const Duration(seconds: 8),
          action: SnackBarAction(
              label: "Details",
              onPressed: () => showDialog(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                        content: SingleChildScrollView(
                          child: SelectableText(
                              "${record.message}\n${record.error}\n${record.object}\n${record.stackTrace}"),
                        ),
                      ))),
        ));
      }
    });
  }

  PreferredSize? getErrorBar() {
    final data = context.watch<DataProvider>();

    if (data.failedPatches.isNotEmpty) {
      return PreferredSize(
        preferredSize: const Size.fromHeight(36),
        child: InkWell(
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const FailedPatchStorage(),
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
    final identityProvider = context.watch<IdentityProvider>();
    String? tbaKey = context.watch<DataProvider>().event.config.tbaEventId;
    final serverConnection = context.watch<DataProvider>();

    return Scaffold(
      appBar: AppBar(
        bottom: getErrorBar(),
        titleSpacing: 0,
        title: Text(data.event.config.name),
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
        const TeamGridList(showEditButton: true),
        const AnalysisPage(),
        const DocumentationScreen(),
      ][_currentPageIndex],
      drawer: Drawer(
        child: ListView(children: [
          ListTile(
            title: const Text("Identity"),
            subtitle: Text(identityProvider.identity),
            trailing: IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                final result = await showStringInputDialog(
                    context, "Identity", identityProvider.identity);
                if (result != null) {
                  await identityProvider.setIdentity(result);
                }
              },
            ),
          ),
          ListTile(
            title: const Text("Data Source"),
            subtitle: Text(serverConnection.serverURL),
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ConfigureSourceScreen(),
                )),
          ),
          const Divider(),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: FilledButton(
                  onPressed: () {
                    final data = context.read<DataProvider>().database;
                    final stream =
                        Stream.fromIterable(utf8.encode(json.encode(data)));
                    download(stream, '${data.event.config.name}.json');
                  },
                  child: const Text("Download DB as File")),
            ),
          ),
          ListTile(
            title: const Text("Edit History"),
            trailing: const Icon(Icons.receipt_long),
            subtitle:
                Text('${data.database.patches.length.toString()} entries'),
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PatchHistoryPage(),
                )),
          ),
          ListTile(
            title: const Text("Scouting Leaderboard"),
            trailing: const Icon(Icons.leaderboard),
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ScoutLeaderboardPage(),
                )),
          ),
          const Divider(),
          ListTile(
            title: const Text("Event Config"),
            subtitle: Text(data.event.config.name),
            trailing: IconButton(
                onPressed: () async {
                  final identity = context.read<IdentityProvider>().identity;
                  final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => JSONEditor(
                          validate: EventConfig.fromJson,
                          source: context.read<DataProvider>().event.config,
                        ),
                      ));

                  if (result != null) {
                    Patch patch = Patch(
                        identity: identity,
                        time: DateTime.now(),
                        path: Patch.buildPath(['config']),
                        value: json.decode(result));
                    //Save the scouting results to the server!!
                    await data.submitPatch(patch);
                  }
                },
                icon: const Icon(Icons.edit)),
          ),
          ListTile(
            title: const Text("Set Pit Map Image"),
            trailing: IconButton(
                onPressed: () async {
                  final identity = context.read<IdentityProvider>().identity;

                  String result;
                  //TAKE PHOTO
                  try {
                    final photo = await pickOrTakeImageDialog(context);
                    if (photo != null) {
                      Uint8List bytes = await photo.readAsBytes();
                      result = base64Encode(bytes);
                      Patch patch = Patch(
                          identity: identity,
                          time: DateTime.now(),
                          path: Patch.buildPath(['pitmap']),
                          value: result);
                      //Save the scouting results to the server!!
                      await data.submitPatch(patch);
                    }
                  } catch (e, s) {
                    Logger.root.severe("Error taking image from device", e, s);
                  }
                },
                icon: const Icon(Icons.camera_alt)),
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
          NavigationDestination(
            selectedIcon: Icon(Icons.book),
            icon: Icon(Icons.book_outlined),
            label: 'Docs',
          ),
        ],
      ),
    );
  }
}
