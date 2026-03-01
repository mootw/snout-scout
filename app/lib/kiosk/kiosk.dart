import 'dart:async';

import 'package:app/kiosk/kiosk_dashboard.dart';
import 'package:app/kiosk/kiosk_provider.dart';
import 'package:app/main.dart';
import 'package:app/providers/data_provider.dart';
import 'package:app/providers/identity_provider.dart';
import 'package:app/providers/local_config_provider.dart';
import 'package:app/screens/scout_authenticator_dialog.dart';
import 'package:app/style.dart';
import 'package:app/widgets/match_card.dart';
import 'package:app/widgets/timeduration.dart';
import 'package:archive/archive.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snout_db/event/match_schedule_item.dart';

const Duration idleTimeout = Duration(minutes: 2);

class Kiosk extends StatefulWidget {
  final Uri dataSource;

  const Kiosk({super.key, required this.dataSource});

  @override
  State<Kiosk> createState() => _KioskState();
}

class _KioskState extends State<Kiosk> {
  Timer? _idleTimer;
  final NavigatorObserver _observer = NavigatorObserver();
  Archive? _kioskData;
  late final GlobalKey<NavigatorState> _navigatorKey;

  @override
  void initState() {
    super.initState();
    _navigatorKey = GlobalKey<NavigatorState>();
    FlutterNativeSplash.remove();
  }

  void _resetKiosk() {
    _observer.navigator?.pushReplacementNamed('/');
  }

  Future<void> _pickFile() async {
    try {
      const XTypeGroup typeGroup = XTypeGroup(
        label: 'kiosk package',
        extensions: <String>['zip'],
        uniformTypeIdentifiers: <String>['kiosk.zip'],
      );

      final XFile? pickedFile = await openFile(
        acceptedTypeGroups: <XTypeGroup>[typeGroup],
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _kioskData = ZipDecoder().decodeBytes(bytes);
        });
      }
    } catch (e, s) {
      Logger.root.severe('$e, $s');
    }
  }

  Future<void> _exitKiosk(BuildContext context) async {
    final AuthorizedScoutData? auth = await showDialog(
      context: context,
      builder: (context) => ScoutAuthorizationDialog(allowBackButton: true),
    );
    if (auth != null) {
      final prefs = await SharedPreferences.getInstance();
      prefs.setBool(kioskModeKey, false);
      main();
    }
  }

  Widget _buildSetupScreen() {
    return Scaffold(
      body: Builder(
        builder: (context) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Snout Scout Kiosk", style: TextStyle(fontSize: 32)),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: _pickFile,
                  child: const Text("Select Kiosk Package (.zip)"),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => _exitKiosk(context),
                  child: const Text("Exit Kiosk Mode"),
                ),
              ],
            ),
          );
        },
      ),
    );
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
        ChangeNotifierProvider<DataProvider>(
          key: Key(widget.dataSource.toString()),
          // Loads the dataprovider in a cleanse mode which filters out some data
          create: (_) => DataProvider(widget.dataSource, true),
        ),
        if (_kioskData != null)
          ChangeNotifierProvider<KioskProvider>(
            // Loads the dataprovider in a cleanse mode which filters out some data
            create: (_) => KioskProvider(kioskFiles: _kioskData!),
          ),
      ],
      child: MaterialApp(
        title: 'Snout Scout Kiosk',
        theme: defaultTheme,
        home: _kioskData == null
            ? _buildSetupScreen()
            : Column(
                children: [
                  Expanded(
                    child: Listener(
                      onPointerDown: (_) {
                        _idleTimer?.cancel();
                        _idleTimer = Timer(idleTimeout, () => _resetKiosk());
                      },
                      child: Column(
                        children: [
                          Material(child: KioskBanner(onReset: _resetKiosk)),
                          Expanded(
                            child: Navigator(
                              key: _navigatorKey,
                              observers: [_observer],
                              onGenerateRoute: (settings) {
                                return MaterialPageRoute(
                                  builder: (context) => KioskDashboard(),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class KioskBanner extends StatelessWidget {
  final VoidCallback onReset;
  const KioskBanner({super.key, required this.onReset});

  @override
  Widget build(BuildContext context) {
    final snoutData = context.watch<DataProvider>();
    Duration? scheduleDelay = snoutData.event.scheduleDelay;
    MatchScheduleItem? teamNextMatch = snoutData.event.nextMatchForTeam(
      snoutData.event.config.team,
    );
    final nextMatch = snoutData.event.nextMatch;

    return Column(
      children: [
        AbsorbPointer(
          child: Column(
            children: [
              SizedBox(height: 4),
              Row(
                children: [
                  if (scheduleDelay != null && teamNextMatch != null)
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Text(
                            'Edits: ${snoutData.database.actions.length.toString()}',
                          ),
                          if (nextMatch != null)
                            MatchCard(
                              match: nextMatch.getData(snoutData.event),
                              results: snoutData.event.getMatchResults(
                                nextMatch.id,
                              ),
                              matchSchedule: nextMatch,
                              focusTeam: snoutData.event.config.team,
                            ),
                          MatchCard(
                            match: teamNextMatch.getData(snoutData.event),
                            results: snoutData.event.getMatchResults(
                              teamNextMatch.id,
                            ),
                            matchSchedule: teamNextMatch,
                            focusTeam: snoutData.event.config.team,
                          ),
                          TimeDuration(
                            time: teamNextMatch.scheduledTime.add(
                              scheduleDelay,
                            ),
                            displayDurationDefault: true,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              SizedBox(height: 4),
            ],
          ),
        ),
        Row(
          children: [
            Expanded(
              child: Container(
                color: Colors.green[900],
                child: InkWell(
                  child: Center(
                    child: Text('Reset Kiosk', style: TextStyle(fontSize: 18)),
                  ),
                  onTap: () => onReset(),
                ),
              ),
            ),
            Container(
              color: Colors.brown,
              child: InkWell(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text('Exit', style: TextStyle(fontSize: 18)),
                  ),
                ),
                onTap: () async {
                  final AuthorizedScoutData? auth = await showDialog(
                    context: context,
                    builder: (innerContext) =>
                        ScoutAuthorizationDialog(allowBackButton: true),
                  );
                  if (auth != null) {
                    final prefs = await SharedPreferences.getInstance();
                    prefs.setBool(kioskModeKey, false);
                    main();
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
