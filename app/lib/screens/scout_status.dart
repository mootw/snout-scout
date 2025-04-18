import 'package:app/providers/data_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


Map<String, dynamic> getScoutStatus (DataProvider provider) {
  final recentEvents = provider.database.patches.where((patch) => patch.time.isAfter(DateTime.now().subtract(Duration(minutes: 10))));
  final eventsMap = Map.fromEntries([...recentEvents.map((e) => MapEntry(e.identity, (e.time, e.path)))]);
  return eventsMap;
}

class ScoutStatusPage extends StatelessWidget {
  const ScoutStatusPage({super.key});

  @override
  Widget build(BuildContext context) {

    final scoutStatus = getScoutStatus(context.watch<DataProvider>());

    return Scaffold(
      appBar: AppBar(title: const Text("Live Scout Status")),
      body: ListView(
        children: [
          for (final scout in scoutStatus.entries)
            ListTile(
              title: Text(scout.key),
              subtitle: Text(scout.value.$2),
              trailing: Text(
                "${DateTime.now().difference(scout.value.$1).inMinutes} min(s) ago",
              ),
            ),
          if (scoutStatus.isEmpty) const Text("No active scouts"),
        ],
      ),
    );
  }
}
