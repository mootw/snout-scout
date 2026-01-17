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
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snout_db/event/match_schedule_item.dart';

const Duration idleTimeout = Duration(minutes: 2);

class Kiosk extends StatefulWidget {
  final Uri dataSource;
  final Archive kioskData;

  const Kiosk({super.key, required this.dataSource, required this.kioskData});

  @override
  State<Kiosk> createState() => _KioskState();
}

class _KioskState extends State<Kiosk> {
  Timer? _idleTimer;
  final NavigatorObserver _observer = NavigatorObserver();

  @override
  void initState() {
    super.initState();
  }

  void _resetKiosk() {
    _observer.navigator?.pushReplacementNamed('/');
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
        ChangeNotifierProvider<KioskProvider>(
          // Loads the dataprovider in a cleanse mode which filters out some data
          create: (_) => KioskProvider(kioskData: widget.kioskData),
        ),
      ],
      child: Column(
        children: [
          Expanded(
            child: Listener(
              onPointerDown: (ptr) {
                _idleTimer?.cancel();
                _idleTimer = Timer(idleTimeout, () => _resetKiosk());
              },
              child: MaterialApp(
                title: 'Snout Scout Kiosk',
                theme: defaultTheme,
                home: Column(
                  children: [
                    Material(child: KioskBanner(onReset: _resetKiosk)),
                    Expanded(
                      child: Navigator(
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
          ),
        ],
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
          child: Row(
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
                        time: teamNextMatch.scheduledTime.add(scheduleDelay),
                        displayDurationDefault: true,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        Row(
          children: [
            Expanded(
              child: Container(
                color: Colors.green[900],
                child: InkWell(
                  child: Center(child: Text('Reset Kiosk')),
                  onTap: () => onReset(),
                ),
              ),
            ),
            Container(
              width: 40,
              color: Colors.brown,
              child: InkWell(
                child: Center(child: Text('Exit')),
                onTap: () async {
                  final AuthorizedScoutData? auth = await showDialog(
                    context: context,
                    builder: (context) =>
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
