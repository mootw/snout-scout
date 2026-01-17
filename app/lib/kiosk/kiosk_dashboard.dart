import 'dart:convert';

import 'package:app/kiosk/auto_scroller.dart';
import 'package:app/kiosk/kiosk_provider.dart';
import 'package:app/providers/data_provider.dart';
import 'package:app/screens/analysis.dart';
import 'package:app/screens/schedule_page.dart';
import 'package:app/screens/teams_page.dart';
import 'package:app/widgets/load_status_or_error_bar.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher_string.dart';

class KioskDashboard extends StatefulWidget {
  const KioskDashboard({super.key});

  @override
  State<KioskDashboard> createState() => _KioskDashboardState();
}

class _KioskDashboardState extends State<KioskDashboard>
    with WidgetsBindingObserver {
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
      );
    }

    return Scaffold(body: KioskHome());
  }
}

class KioskHome extends StatelessWidget {
  const KioskHome({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.read<DataProvider>();

    final nextMatch = data.event.nextMatch;

    final robotGlb = context.read<KioskProvider>().kioskData.firstWhereOrNull(
      (e) => e.isFile && e.name.endsWith('robot.glb'),
    );

    // TODO generate this once rather than on each build since it is a static value.
    final glbDataString = robotGlb == null
        ? null
        : 'data:model/gltf-binary;base64,${base64Encode(robotGlb.content)}';

    return Column(
      children: [
        Expanded(
          flex: 4,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'Our Robot',
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                    Expanded(
                      child: glbDataString == null
                          ? Text('/robot.glb')
                          : ModelViewer(
                              // Handles conflicts with the
                              backgroundColor: Theme.of(context).canvasColor,
                              debugLogging: false,
                              // For some reason it is way too bright by default. Guessing underlying config is weird
                              exposure: 0.7,
                              src: glbDataString,
                              // Plays the first animation found in the model automatically
                              autoPlay: true,
                              //src: 'https://modelviewer.dev/shared-assets/models/Astronaut.glb',
                              autoRotate: true,
                            ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'Our Team',
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                    Expanded(
                      child: Container(
                        color: Colors.black,
                        alignment: Alignment.center,
                        child: Text('TODO SLIDESHOW'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const Divider(height: 0),

        Expanded(
          flex: 5,
          child: Row(
            children: [
              SizedBox(
                width: 350,
                child: Column(
                  children: [
                    Expanded(
                      child: AllMatchesPage(
                        key: Key(nextMatch?.id ?? 'no_match'),
                        scrollPosition: nextMatch,
                      ),
                    ),
                    Divider(height: 0),
                    ListTile(
                      title: const Text('Hire Me'),
                      subtitle: const Text('https://portfolio.xqkz.net'),
                      leading: const Icon(Icons.work),
                      onTap: () =>
                          launchUrlString('https://portfolio.xqkz.net/'),
                    ),
                  ],
                ),
              ),
              VerticalDivider(width: 0),
              Expanded(
                child: Row(
                  children: [
                    SizedBox(
                      width: 250,
                      child: AutoScroller(child: const AnalysisPage()),
                    ),
                    Expanded(
                      child: AutoScroller(
                        child: const TeamGridList(showEditButton: false),
                      ),
                    ),
                  ],
                ),
              ),

              // Expanded(
              //   child: Container(
              //     clipBehavior: Clip.hardEdge,
              //     decoration: BoxDecoration(
              //       border: Border.all(color: Colors.white),
              //     ),
              //     child: KioskInfoCycle(),
              //   ),
              // ),
            ],
          ),
        ),
      ],
    );
  }
}
