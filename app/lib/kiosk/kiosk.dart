import 'dart:async';

import 'package:app/main.dart';
import 'package:app/providers/data_provider.dart';
import 'package:app/providers/identity_provider.dart';
import 'package:app/providers/local_config_provider.dart';
import 'package:app/style.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// This is a very bad kiosk screen with ALMOST no regard to security
void runKiosk(Uri dataSource) {
  runApp(Kiosk(dataSource: dataSource));
}

const Duration idleTimeout = Duration(minutes: 3);

// TODO Have a list of teams that can be selected from
// TODO Have a rotating caurosel of interesting stats and tables and stuff
class Kiosk extends StatefulWidget {
  final Uri dataSource;

  const Kiosk({super.key, required this.dataSource});

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
          create: (_) => DataProvider(widget.dataSource, true),
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
                      child: Container(
                        width: double.infinity,
                        color: Colors.green[900],
                        child: InkWell(
                          child: Center(child: Text('Reset Kiosk')),
                          onTap: () => _resetKiosk(),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Navigator(
                        observers: [_observer],
                        onGenerateRoute: (settings) {
                          return MaterialPageRoute(
                            builder: (context) => DatabaseBrowserScreen(),
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
