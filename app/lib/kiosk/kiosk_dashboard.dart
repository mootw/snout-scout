import 'package:app/kiosk/auto_scroller.dart';
import 'package:app/kiosk/kiosk_provider.dart';
import 'package:app/kiosk/media_cycle.dart';
import 'package:app/providers/data_provider.dart';
import 'package:app/screens/analysis.dart';
import 'package:app/screens/schedule_page.dart';
import 'package:app/screens/teams_page.dart';
import 'package:app/widgets/load_status_or_error_bar.dart';
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

class KioskHome extends StatefulWidget {
  const KioskHome({super.key});

  @override
  State<KioskHome> createState() => _KioskHomeState();
}

class _KioskHomeState extends State<KioskHome> {
  String? _selectedModel;

  @override
  void initState() {
    super.initState();
    _selectedModel = context.read<KioskProvider>().primaryModel;
  }

  @override
  Widget build(BuildContext context) {
    final data = context.read<DataProvider>();

    final nextMatch = data.event.nextMatch;

    final kioskProvider = context.watch<KioskProvider>();

    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: kioskProvider.encodedModels[_selectedModel] == null
                          ? Text('ROBOT MODEL $_selectedModel is invalid')
                          : ModelViewer(
                              // Handles conflicts with the
                              backgroundColor: Theme.of(context).canvasColor,
                              debugLogging: false,
                              // For some reason it is way too bright by default. Guessing underlying config is weird
                              exposure: 0.7,
                              src: kioskProvider.encodedModels[_selectedModel]!,
                              // Plays the first animation found in the model automatically
                              autoPlay: true,
                              //src: 'https://modelviewer.dev/shared-assets/models/Astronaut.glb',
                              autoRotate: true,
                            ),
                    ),
                    Wrap(
                      children: [
                        for (final model in kioskProvider.encodedModels.keys)
                          ChoiceChip(
                            selected: _selectedModel == model,
                            label: Text(model),

                            onSelected: (isSelected) => setState(() {
                              if (isSelected) {
                                _selectedModel = model;
                              }
                            }),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: Container(
                        color: Colors.black,
                        alignment: Alignment.center,
                        child: MediaCycle(media: kioskProvider.slideshow),
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
