import 'package:app/kiosk/stat_cylce.dart';
import 'package:app/providers/data_provider.dart';
import 'package:app/screens/analysis.dart';
import 'package:app/screens/schedule_page.dart';
import 'package:app/screens/select_data_source.dart';
import 'package:app/screens/teams_page.dart';
import 'package:app/style.dart';
import 'package:app/widgets/load_status_or_error_bar.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';

class KioskDashboard extends StatefulWidget {
  const KioskDashboard({super.key});

  @override
  State<KioskDashboard> createState() => _KioskDashboardState();
}

class _KioskDashboardState extends State<KioskDashboard>
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
              KioskHome(),
              AllMatchesPage(
                // 10/10 hack to make the widget re-scroll to the correct spot on load
                // this will force it to scroll whenever the matches length changes
                // we could add another value here to make it scroll on other changes too
                key: Key(data.event.matches.length.toString()),
                scrollPosition: nextMatch,
              ),
              const TeamGridList(showEditButton: true),
              const AnalysisPage(),
            ][_currentPageIndex],
          ),
        ],
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
    selectedIcon: Icon(Icons.home),
    icon: Icon(Icons.home_outlined),
    label: 'Home',
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
];

class KioskHome extends StatelessWidget {
  const KioskHome({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.read<DataProvider>().event;
    return Column(
      children: [
        SizedBox(height: 12),
        Text(
          'Want to learn more about our robot?',
          style: Theme.of(context).textTheme.displayMedium,
        ),
        Container(height: 300, width: 750, color: Colors.red),
        FilledButton(
          onPressed: () => {
            // TODO go to promo page
          },
          child: Text("Learn more about ${data.config.team}"),
        ),

        SizedBox(height: 24),
        Text(
          'Want to learn more about another robot?',
          style: Theme.of(context).textTheme.displayMedium,
        ),
        Text(
          'Here are some cool stats we have collected. To see more, check out the navigation on the left',
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Container(
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white),
              ),
              child: KioskInfoCycle(),
            ),
          ),
        ),
      ],
    );
  }
}
