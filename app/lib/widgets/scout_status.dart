import 'package:app/providers/data_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


Map<String, dynamic> getScoutStatus (DataProvider provider) {
  final recentEvents = provider.database.patches.where((patch) => patch.time.isAfter(DateTime.now().subtract(Duration(minutes: 15))));
  final eventsMap = Map.fromEntries([...recentEvents.map((e) => MapEntry(e.identity, (e.time, e.path)))]);
  return eventsMap;
}

class ScoutStatus extends StatelessWidget {
  const ScoutStatus({super.key});

  @override
  Widget build(BuildContext context) {

    final scoutStatus = getScoutStatus(context.watch<DataProvider>());

    return Column(
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
      );
  }
}
