import 'package:app/providers/data_provider.dart';
import 'package:app/widgets/scout_name_display.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:snout_db/pubkey.dart';

Map<Pubkey, dynamic> getScoutStatus(DataProvider provider) {
  final recentEvents = provider.database.actions.where(
    (message) => message.payload.time.isAfter(
      DateTime.now().subtract(Duration(minutes: 15)),
    ),
  );
  final eventsMap = Map.fromEntries([
    ...recentEvents.map(
      (e) => MapEntry(e.author, (e.payload.time, e.payload.action.toString())),
    ),
  ]);
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
            title: Align(
              alignment: Alignment.centerLeft,
              child: ScoutName(
                db: context.watch<DataProvider>().database,
                scoutPubkey: scout.key,
              ),
            ),
            subtitle: Text(scout.value.$2.toString()),
            trailing: Text(
              "${DateTime.now().difference(scout.value.$1).inMinutes} min(s) ago",
            ),
          ),
        if (scoutStatus.isEmpty) const Text("No active scouts"),
      ],
    );
  }
}
