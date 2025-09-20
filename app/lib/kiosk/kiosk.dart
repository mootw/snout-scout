import 'dart:async';

import 'package:app/kiosk/kiosk_dashboard.dart';
import 'package:app/providers/data_provider.dart';
import 'package:app/providers/identity_provider.dart';
import 'package:app/providers/local_config_provider.dart';
import 'package:app/style.dart';
import 'package:app/widgets/match_card.dart';
import 'package:app/widgets/timeduration.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:snout_db/event/match_schedule_item.dart';

class KioskSettings {
  List<String> safeIds;

  KioskSettings({required this.safeIds});
}

// This is a very bad kiosk screen with ALMOST no regard to security
void runKiosk(Uri dataSource, KioskSettings settings) {
  runApp(Kiosk(dataSource: dataSource, settings: settings));
}

const Duration idleTimeout = Duration(minutes: 2);

// TODO Have a list of teams that can be selected from
// TODO Have a rotating caurosel of interesting stats and tables and stuff
class Kiosk extends StatefulWidget {
  final Uri dataSource;
  final KioskSettings settings;

  const Kiosk({super.key, required this.dataSource, required this.settings});

  @override
  State<Kiosk> createState() => _KioskState();
}

class _KioskState extends State<Kiosk> {
  Timer? _idleTimer;
  final NavigatorObserver _observer = NavigatorObserver();

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
          create:
              (_) => DataProvider(widget.dataSource, widget.settings.safeIds),
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
                    Material(
                      child: Column(
                        children: [
                          KioskBanner(),
                          Container(
                            width: double.infinity,
                            color: Colors.green[900],
                            child: InkWell(
                              child: Center(child: Text('Reset Kiosk')),
                              onTap: () => _resetKiosk(),
                            ),
                          ),
                        ],
                      ),
                    ),
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
  const KioskBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final snoutData = context.watch<DataProvider>();
    Duration? scheduleDelay = snoutData.event.scheduleDelay;
    MatchScheduleItem? teamNextMatch = snoutData.event.nextMatchForTeam(
      snoutData.event.config.team,
    );
    final nextMatch = snoutData.event.nextMatch;

    return Row(
      children: [
        if (scheduleDelay != null && teamNextMatch != null)
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text('Edits: ${snoutData.database.patches.length.toString()}'),
                if (nextMatch != null)
                  MatchCard(
                    match: nextMatch.getData(snoutData.event),
                    matchSchedule: nextMatch,
                    focusTeam: snoutData.event.config.team,
                  ),
                MatchCard(
                  match: teamNextMatch.getData(snoutData.event),
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
    );
  }
}
