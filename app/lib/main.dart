import 'dart:async';
import 'dart:convert';

import 'package:app/config_editor/config_editor.dart';
import 'package:app/data_submit_login.dart';
import 'package:app/kiosk/kiosk.dart';
import 'package:app/providers/data_provider.dart';
import 'package:app/providers/local_config_provider.dart';
import 'package:app/screens/dashboard.dart';
import 'package:app/screens/scout_authenticator_dialog.dart';
import 'package:app/screens/teams_lists.dart';
import 'package:app/services/data_service.dart';
import 'package:app/style.dart';
import 'package:app/providers/identity_provider.dart';
import 'package:app/screens/analysis.dart';
import 'package:app/screens/select_data_source.dart';
import 'package:app/screens/edit_json.dart';
import 'package:app/screens/chain_history.dart';
import 'package:app/screens/schedule_page.dart';
import 'package:app/screens/teams_page.dart';
import 'package:app/search.dart';
import 'package:app/widgets/load_status_or_error_bar.dart';
import 'package:cbor/cbor.dart';
import 'package:download/download.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:logging/logging.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snout_db/actions/write_config.dart';
import 'package:snout_db/snout_chain.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:archive/archive.dart';

/// Only update this value when there is a VALID data source loaded,
const String defaultSourceKey = 'default_source_uri';

const String kioskModeKey = 'kiosk_mode';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    // ignore: avoid_print
    print(details.stack);
  };

  Logger.root.onRecord.listen((record) {
    // For now logging will always print to console,
    // since the app is open source we're ok with that..
    // at some point it might make sense to actually write
    // these logs to a file so they can be pulled later!
    // ignore: avoid_print
    print(
      '${record.level.name}: ${record.time}: ${record.message}\n${record.error}\n${record.stackTrace}',
    );
  });

  final prefs = await SharedPreferences.getInstance();

  // Check if the device has a Data Source Selected.
  final defaultDataSource = prefs.getString(defaultSourceKey);
  final ds = defaultDataSource == null ? null : Uri.parse(defaultDataSource);

  final kioskMode = prefs.getBool(kioskModeKey) ?? false;

  if (ds != null && kioskMode) {
    try {
      print('Running in kiosk mode with data source $ds');
      final file = fs.file('${fs.directory('/kiosk').path}/kiosk.zip');

      final bytes = await file.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      runApp(Kiosk(dataSource: ds, kioskData: archive));
      return;
    } catch (e, s) {
      print('$e, $s');
    }
  }
  runApp(SnoutScoutApp(defaultSourceKey: ds));
}

class SnoutScoutApp extends StatefulWidget {
  final Uri? defaultSourceKey;

  const SnoutScoutApp({this.defaultSourceKey, super.key});

  static SnoutScoutAppState? getState(BuildContext context) {
    return context.findAncestorStateOfType<SnoutScoutAppState>();
  }

  @override
  State<SnoutScoutApp> createState() => SnoutScoutAppState();
}

class SnoutScoutAppState extends State<SnoutScoutApp> {
  Uri? _dataSource;

  Future setSource(Uri newSource) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(defaultSourceKey, newSource.toString());
    setState(() {
      _dataSource = newSource;
    });
  }

  @override
  void initState() {
    super.initState();
    // Keep the splash up for 3 extra seconds
    Future.delayed(
      Duration(seconds: 3),
    ).then((onValue) => FlutterNativeSplash.remove());
    _dataSource = widget.defaultSourceKey;
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<IdentityProvider>(
          create: (_) => IdentityProvider(),
        ),
        ChangeNotifierProvider<LocalConfigProvider>(
          create: (_) => LocalConfigProvider(),
        ),
        // TODO make this a separate widget or something, right now i dont think they get closed out.
        if (_dataSource != null)
          ChangeNotifierProvider<DataProvider>(
            key: Key(_dataSource.toString()),
            create: (_) => DataProvider(_dataSource!),
          ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Snout Scout',
        onGenerateRoute: (settings) {
          final name = settings.name;
          if (name != null) {
            final uri = Uri.tryParse(Uri.decodeComponent(name.substring(1)));
            if (uri != null) {
              setSource(uri);
              setState(() {
                _dataSource = uri;
              });
            }
          }
          return null;
        },
        theme: defaultTheme,
        home: _dataSource != null
            ? const DatabaseBrowserScreen()
            : const SelectDataSourceScreen(),
      ),
    );
  }
}

class DatabaseBrowserScreen extends StatefulWidget {
  const DatabaseBrowserScreen({super.key});

  @override
  State<DatabaseBrowserScreen> createState() => _DatabaseBrowserScreenState();
}

class _DatabaseBrowserScreenState extends State<DatabaseBrowserScreen>
    with WidgetsBindingObserver {
  int _currentPageIndex = 0;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);
    Logger.root.onRecord.listen((record) {
      if (record.level >= Level.SEVERE) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(record.message),
              duration: const Duration(seconds: 8),
              action: SnackBarAction(
                label: "Details",
                onPressed: () => showDialog(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    content: SingleChildScrollView(
                      child: SelectableText(
                        "${record.message}\n${record.error}\n${record.object}\n${record.stackTrace}",
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Update the app if
    if (state == AppLifecycleState.resumed) {
      // Update the stuffs yay
      context.read<DataProvider>().lifecycleListener();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final serverConnection = context.watch<DataProvider>();

    if (data.isInitialLoad == false) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            "Loading ${Uri.decodeFull(serverConnection.dataSourceUri.toString())}",
          ),
          bottom: LoadOrErrorStatusBar(),
        ),
        body: TextButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SelectDataSourceScreen(),
            ),
          ),
          child: Text("Change Source"),
        ),
      );
    }

    final nextMatch = data.event.nextMatch;

    final largeDevice = isLargeDevice(context);

    return Scaffold(
      appBar: AppBar(
        bottom: const LoadOrErrorStatusBar(),
        titleSpacing: 0,
        title: Text(data.event.config.name),
        actions: [
          IconButton(
            onPressed: () =>
                showSearch(context: context, delegate: SnoutScoutSearch()),
            icon: const Icon(Icons.search),
          ),
          SizedBox(width: 4),
        ],
      ),
      body: Row(
        children: [
          if (largeDevice)
            NavigationRail(
              backgroundColor: Theme.of(
                context,
              ).bottomNavigationBarTheme.backgroundColor,
              labelType: NavigationRailLabelType.all,
              onDestinationSelected: (int index) {
                setState(() {
                  _currentPageIndex = index;
                });
              },
              destinations: navigationDestinations
                  .map(
                    (e) => NavigationRailDestination(
                      selectedIcon: e.selectedIcon,
                      icon: e.icon,
                      label: Text(e.label),
                    ),
                  )
                  .toList(),
              selectedIndex: _currentPageIndex,
            ),
          Expanded(
            child: [
              DashboardPage(),
              AllMatchesPage(
                // 10/10 hack to make the widget re-scroll to the correct spot on load
                // this will force it to scroll whenever the matches length changes
                // we could add another value here to make it scroll on other changes too
                key: Key(data.event.matches.length.toString()),
                scrollPosition: nextMatch,
              ),
              const TeamGridList(showEditButton: true),
              const AnalysisPage(),
              const TeamListsPage(),
            ][_currentPageIndex],
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            ListTile(
              leading: Icon(Icons.dataset),
              title: const Text("Data Source"),
              subtitle: Text(
                Uri.decodeFull(serverConnection.dataSourceUri.toString()),
              ),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SelectDataSourceScreen(),
                ),
              ),
            ),
            ListTile(
              title: const Text("Register"),
              leading: const Icon(Icons.account_circle),
              onTap: () => registerNewScout(context),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: FilledButton.tonal(
                  onPressed: () {
                    final data = context.read<DataProvider>().database;
                    final stream = Stream.fromIterable(
                      cbor.encode(SnoutDBFile(actions: data.actions).toCbor()),
                    );
                    download(stream, '${data.event.config.name}.snoutdb');
                  },
                  child: const Text("Download DB as File"),
                ),
              ),
            ),
            const Divider(),
            ListTile(
              title: const Text("Ledger"),
              trailing: const Icon(Icons.receipt_long),
              subtitle: Text(
                '${data.database.actions.length.toString()} transactions',
              ),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ActionChainHistoryPage(),
                ),
              ),
            ),
            const Divider(),
            ListTile(
              title: const Text("Event Config"),
              leading: const Icon(Icons.edit),
              onTap: () async {
                final config = context.read<DataProvider>().event.config;

                final EventConfig? result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ConfigEditorPage(initialState: config),
                  ),
                );

                if (result != null) {
                  final writeConfig = ActionWriteConfig(result);
                  //Save the scouting results to the server!!
                  if (context.mounted) {
                    await submitData(context, writeConfig);
                  }
                }
              },
            ),
            ListTile(
              title: const Text("Event Config (JSON)"),
              leading: const Icon(Icons.data_object),
              onTap: () async {
                final config = context.read<DataProvider>().event.config;

                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => JSONEditor(
                      validate: EventConfig.fromJson,
                      source: config,
                    ),
                  ),
                );

                if (result != null) {
                  final modAsConfig = EventConfig.fromJson(jsonDecode(result));
                  final writeConfig = ActionWriteConfig(modAsConfig);
                  if (context.mounted) {
                    await submitData(context, writeConfig);
                  }
                }
              },
            ),
            ListTile(
              title: const Text("Kiosk Mode"),
              subtitle: const Text("Restarts App. Requires password to exit."),
              trailing: const Icon(Icons.screen_share_outlined),
              onTap: () async {
                const XTypeGroup typeGroup = XTypeGroup(
                  label: 'kiosk package',
                  extensions: <String>['zip'],
                  uniformTypeIdentifiers: <String>['kiosk.zip'],
                );

                final XFile? pickedFile = await openFile(
                  acceptedTypeGroups: <XTypeGroup>[typeGroup],
                );

                if (pickedFile != null) {
                  final fileBytes = await pickedFile.readAsBytes();
                  // Ensure that the archive is decodable
                  final archive = ZipDecoder().decodeBytes(fileBytes);

                  final file = fs.file(
                    '${fs.directory('/kiosk').path}/kiosk.zip',
                  );
                  if (await file.exists() == false) {
                    await file.create(recursive: true);
                  }
                  await file.writeAsBytes(fileBytes, flush: true);

                  final prefs = await SharedPreferences.getInstance();
                  prefs.setBool(kioskModeKey, true);
                  main();
                }
              },
            ),
            ListTile(
              title: const Text("App Version"),
              subtitle: FutureBuilder<PackageInfo>(
                future: PackageInfo.fromPlatform(),
                builder: (context, snapshot) {
                  switch (snapshot.connectionState) {
                    case ConnectionState.done:
                      return Text(snapshot.data?.version ?? "unknown");
                    default:
                      return const SizedBox();
                  }
                },
              ),
              trailing: Text('Runtime: ${kIsWasm ? 'WASM' : 'JS'}'),
            ),
            ListTile(
              title: const Text('Hire Me'),
              subtitle: const Text('https://portfolio.xqkz.net'),
              leading: const Icon(Icons.work),
              onTap: () => launchUrlString('https://portfolio.xqkz.net/'),
            ),
          ],
        ),
      ),
      bottomNavigationBar: largeDevice
          ? null
          : NavigationBar(
              onDestinationSelected: (int index) {
                setState(() {
                  _currentPageIndex = index;
                });
              },
              selectedIndex: _currentPageIndex,
              destinations: navigationDestinations,
            ),
    );
  }
}

const navigationDestinations = [
  NavigationDestination(
    selectedIcon: Icon(Icons.dashboard),
    icon: Icon(Icons.dashboard_outlined),
    label: 'Dashboard',
  ),
  NavigationDestination(
    selectedIcon: Icon(Icons.calendar_today),
    icon: Icon(Icons.calendar_today_outlined),
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
    selectedIcon: Icon(Icons.list),
    icon: Icon(Icons.list_outlined),
    label: 'Lists',
  ),
];
