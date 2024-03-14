import 'package:app/providers/data_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ScoutStatusPage extends StatelessWidget {

  const ScoutStatusPage({super.key});

  @override
  Widget build(BuildContext context) {
    final scoutStatus = context.watch<DataProvider>().scoutStatus;
    context.read<DataProvider>().updateStatus(context, "Watching Scouts");
    return Scaffold(
      appBar: AppBar(
        title: const Text("Live Scout Status"),
      ),
      body: ListView(
        children: [
          for (final scout in scoutStatus)
            ListTile(
              title: Text(scout.identity),
              subtitle: Text(scout.status),
              trailing: Text("${DateTime.now().difference(scout.time).inMinutes} min(s) ago"),
            ),
            if(scoutStatus.isEmpty)
              const Text("No active scouts"),
        ],
      ),
    );
  }
}
