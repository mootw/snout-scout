import 'dart:convert';

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
import 'package:model_viewer_plus/model_viewer_plus.dart';
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

const exampleRobotGlb = 'Z2xURgIAAABUDQAA8AYAAEpTT057ImFzc2V0Ijp7ImdlbmVyYXRvciI6Iktocm9ub3MgZ2xURiBCbGVuZGVyIEkvTyB2NS4wLjIxIiwidmVyc2lvbiI6IjIuMCJ9LCJzY2VuZSI6MCwic2NlbmVzIjpbeyJuYW1lIjoiU2NlbmUiLCJub2RlcyI6WzAsMV19XSwibm9kZXMiOlt7Im1lc2giOjAsIm5hbWUiOiJDdWJlIiwic2NhbGUiOlsxLDAuMjczMjIyMzI3MjMyMzYwODQsMV19LHsibWVzaCI6MSwibmFtZSI6IkN1YmUuMDAxIiwic2NhbGUiOlswLjM2OTY5ODI4NjA1NjUxODU1LDAuNjU4Mjg5NzMwNTQ4ODU4NiwwLjM2OTY5ODI4NjA1NjUxODU1XSwidHJhbnNsYXRpb24iOlswLDAuNzY3Njc5MDM1NjYzNjA0NywwXX1dLCJtYXRlcmlhbHMiOlt7ImRvdWJsZVNpZGVkIjp0cnVlLCJuYW1lIjoiTWF0ZXJpYWwiLCJwYnJNZXRhbGxpY1JvdWdobmVzcyI6eyJiYXNlQ29sb3JGYWN0b3IiOlswLjAyMjcwMjYyNTAyMTMzODQ2MywwLjAyMzk0NzU4NzIzNjc2MjA0NywwLjgwMDAwNzQ2MjUwMTUyNTksMV0sIm1ldGFsbGljRmFjdG9yIjowLCJyb3VnaG5lc3NGYWN0b3IiOjAuNX19XSwibWVzaGVzIjpbeyJuYW1lIjoiQ3ViZSIsInByaW1pdGl2ZXMiOlt7ImF0dHJpYnV0ZXMiOnsiUE9TSVRJT04iOjAsIk5PUk1BTCI6MSwiVEVYQ09PUkRfMCI6Mn0sImluZGljZXMiOjMsIm1hdGVyaWFsIjowfV19LHsibmFtZSI6IkN1YmUuMDAxIiwicHJpbWl0aXZlcyI6W3siYXR0cmlidXRlcyI6eyJQT1NJVElPTiI6NCwiTk9STUFMIjo1LCJURVhDT09SRF8wIjo2fSwiaW5kaWNlcyI6MywibWF0ZXJpYWwiOjB9XX1dLCJhY2Nlc3NvcnMiOlt7ImJ1ZmZlclZpZXciOjAsImNvbXBvbmVudFR5cGUiOjUxMjYsImNvdW50IjoyNCwibWF4IjpbMSwxLDFdLCJtaW4iOlstMSwtMSwtMV0sInR5cGUiOiJWRUMzIn0seyJidWZmZXJWaWV3IjoxLCJjb21wb25lbnRUeXBlIjo1MTI2LCJjb3VudCI6MjQsInR5cGUiOiJWRUMzIn0seyJidWZmZXJWaWV3IjoyLCJjb21wb25lbnRUeXBlIjo1MTI2LCJjb3VudCI6MjQsInR5cGUiOiJWRUMyIn0seyJidWZmZXJWaWV3IjozLCJjb21wb25lbnRUeXBlIjo1MTIzLCJjb3VudCI6MzYsInR5cGUiOiJTQ0FMQVIifSx7ImJ1ZmZlclZpZXciOjQsImNvbXBvbmVudFR5cGUiOjUxMjYsImNvdW50IjoyNCwibWF4IjpbMSwxLDFdLCJtaW4iOlstMSwtMSwtMV0sInR5cGUiOiJWRUMzIn0seyJidWZmZXJWaWV3Ijo1LCJjb21wb25lbnRUeXBlIjo1MTI2LCJjb3VudCI6MjQsInR5cGUiOiJWRUMzIn0seyJidWZmZXJWaWV3Ijo2LCJjb21wb25lbnRUeXBlIjo1MTI2LCJjb3VudCI6MjQsInR5cGUiOiJWRUMyIn1dLCJidWZmZXJWaWV3cyI6W3siYnVmZmVyIjowLCJieXRlTGVuZ3RoIjoyODgsImJ5dGVPZmZzZXQiOjAsInRhcmdldCI6MzQ5NjJ9LHsiYnVmZmVyIjowLCJieXRlTGVuZ3RoIjoyODgsImJ5dGVPZmZzZXQiOjI4OCwidGFyZ2V0IjozNDk2Mn0seyJidWZmZXIiOjAsImJ5dGVMZW5ndGgiOjE5MiwiYnl0ZU9mZnNldCI6NTc2LCJ0YXJnZXQiOjM0OTYyfSx7ImJ1ZmZlciI6MCwiYnl0ZUxlbmd0aCI6NzIsImJ5dGVPZmZzZXQiOjc2OCwidGFyZ2V0IjozNDk2M30seyJidWZmZXIiOjAsImJ5dGVMZW5ndGgiOjI4OCwiYnl0ZU9mZnNldCI6ODQwLCJ0YXJnZXQiOjM0OTYyfSx7ImJ1ZmZlciI6MCwiYnl0ZUxlbmd0aCI6Mjg4LCJieXRlT2Zmc2V0IjoxMTI4LCJ0YXJnZXQiOjM0OTYyfSx7ImJ1ZmZlciI6MCwiYnl0ZUxlbmd0aCI6MTkyLCJieXRlT2Zmc2V0IjoxNDE2LCJ0YXJnZXQiOjM0OTYyfV0sImJ1ZmZlcnMiOlt7ImJ5dGVMZW5ndGgiOjE2MDh9XX0gICBIBgAAQklOAAAAgD8AAIA/AACAvwAAgD8AAIA/AACAvwAAgD8AAIA/AACAvwAAgD8AAIC/AACAvwAAgD8AAIC/AACAvwAAgD8AAIC/AACAvwAAgD8AAIA/AACAPwAAgD8AAIA/AACAPwAAgD8AAIA/AACAPwAAgD8AAIC/AACAPwAAgD8AAIC/AACAPwAAgD8AAIC/AACAPwAAgL8AAIA/AACAvwAAgL8AAIA/AACAvwAAgL8AAIA/AACAvwAAgL8AAIC/AACAvwAAgL8AAIC/AACAvwAAgL8AAIC/AACAvwAAgL8AAIA/AACAPwAAgL8AAIA/AACAPwAAgL8AAIA/AACAPwAAgL8AAIC/AACAPwAAgL8AAIC/AACAPwAAgL8AAIC/AACAPwAAAAAAAAAAAACAvwAAAAAAAIA/AAAAAAAAgD8AAAAAAAAAAAAAAAAAAAAAAACAvwAAAAAAAIC/AAAAAAAAgD8AAAAAAAAAAAAAAAAAAAAAAACAPwAAAAAAAIA/AAAAAAAAgD8AAAAAAAAAAAAAAAAAAAAAAACAPwAAAAAAAIC/AAAAAAAAgD8AAAAAAAAAAAAAAAAAAAAAAACAvwAAAAAAAIA/AAAAAAAAgL8AAAAAAAAAAAAAAAAAAAAAAACAvwAAAAAAAIC/AAAAAAAAgL8AAAAAAAAAAAAAAAAAAAAAAACAPwAAAAAAAIA/AAAAAAAAgL8AAAAAAAAAAAAAAAAAAAAAAACAPwAAAAAAAIC/AAAAAAAAgL8AAAAAAAAAAAAAID8AAAA/AAAgPwAAAD8AACA/AAAAPwAAwD4AAAA/AADAPgAAAD8AAMA+AAAAPwAAID8AAIA+AAAgPwAAgD4AACA/AACAPgAAwD4AAIA+AADAPgAAgD4AAMA+AACAPgAAID8AAEA/AABgPwAAAD8AACA/AABAPwAAwD4AAEA/AAAAPgAAAD8AAMA+AABAPwAAID8AAAAAAABgPwAAgD4AACA/AACAPwAAwD4AAAAAAAAAPgAAgD4AAMA+AACAPwEADQATAAEAEwAHAAkABgASAAkAEgAVABcAFAAOABcADgARABAABAAKABAACgAWAAUAAgAIAAUACAALAA8ADAAAAA8AAAADAAAAgD8AAIA/AACAvwAAgD8AAIA/AACAvwAAgD8AAIA/AACAvwAAgD8AAIC/AACAvwAAgD8AAIC/AACAvwAAgD8AAIC/AACAvwAAgD8AAIA/AACAPwAAgD8AAIA/AACAPwAAgD8AAIA/AACAPwAAgD8AAIC/AACAPwAAgD8AAIC/AACAPwAAgD8AAIC/AACAPwAAgL8AAIA/AACAvwAAgL8AAIA/AACAvwAAgL8AAIA/AACAvwAAgL8AAIC/AACAvwAAgL8AAIC/AACAvwAAgL8AAIC/AACAvwAAgL8AAIA/AACAPwAAgL8AAIA/AACAPwAAgL8AAIA/AACAPwAAgL8AAIC/AACAPwAAgL8AAIC/AACAPwAAgL8AAIC/AACAPwAAAAAAAAAAAACAvwAAAAAAAIA/AAAAAAAAgD8AAAAAAAAAAAAAAAAAAAAAAACAvwAAAAAAAIC/AAAAAAAAgD8AAAAAAAAAAAAAAAAAAAAAAACAPwAAAAAAAIA/AAAAAAAAgD8AAAAAAAAAAAAAAAAAAAAAAACAPwAAAAAAAIC/AAAAAAAAgD8AAAAAAAAAAAAAAAAAAAAAAACAvwAAAAAAAIA/AAAAAAAAgL8AAAAAAAAAAAAAAAAAAAAAAACAvwAAAAAAAIC/AAAAAAAAgL8AAAAAAAAAAAAAAAAAAAAAAACAPwAAAAAAAIA/AAAAAAAAgL8AAAAAAAAAAAAAAAAAAAAAAACAPwAAAAAAAIC/AAAAAAAAgL8AAAAAAAAAAAAAID8AAAA/AAAgPwAAAD8AACA/AAAAPwAAwD4AAAA/AADAPgAAAD8AAMA+AAAAPwAAID8AAIA+AAAgPwAAgD4AACA/AACAPgAAwD4AAIA+AADAPgAAgD4AAMA+AACAPgAAID8AAEA/AABgPwAAAD8AACA/AABAPwAAwD4AAEA/AAAAPgAAAD8AAMA+AABAPwAAID8AAAAAAABgPwAAgD4AACA/AACAPwAAwD4AAAAAAAAAPgAAgD4AAMA+AACAPw==';

class KioskHome extends StatelessWidget {
  const KioskHome({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.read<DataProvider>().event;
    return Column(
      children: [
        SizedBox(height: 12),
        Text(
          'Our robot',
          style: Theme.of(context).textTheme.displayMedium,
        ),
        
        SizedBox(height: 300, width: 750, child: ModelViewer(
          src: 'data:model/gltf-binary;base64,${base64Encode(base64Decode(exampleRobotGlb))}',
          //src: 'https://modelviewer.dev/shared-assets/models/Astronaut.glb',
          autoRotate: true,
        ),),
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
