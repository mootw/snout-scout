import 'package:app/kiosk/kiosk.dart';
import 'package:app/providers/data_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:snout_db/config/eventconfig.dart';

class KioskConfigurationScreen extends StatefulWidget {
  final EventConfig baseConfig;
  final Uri dataSource;

  const KioskConfigurationScreen({
    super.key,
    required this.dataSource,
    required this.baseConfig,
  });

  @override
  State<KioskConfigurationScreen> createState() =>
      _KioskConfigurationScreenState();
}

class _KioskConfigurationScreenState extends State<KioskConfigurationScreen> {
  @override
  Widget build(BuildContext context) {
    final database = context.read<DataProvider>().database;
    return Scaffold(
      appBar: AppBar(
        title: Text('Kiosk Mode'),
        actions: [
          IconButton(
            onPressed: () {
              runKiosk(
                widget.dataSource,
                KioskSettings(
                  safeIds: <String>[
                    ...database.event.config.pitscouting
                        .where((e) => e.isSensitiveField == false)
                        .map((e) => e.id),
                    ...database.event.config.matchscouting.properties
                        .where((e) => e.isSensitiveField == false)
                        .map((e) => e.id),
                    ...database.event.config.matchscouting.survey
                        .where((e) => e.isSensitiveField == false)
                        .map((e) => e.id),
                    ...database.event.config.matchscouting.processes
                        .where((e) => e.isSensitiveField == false)
                        .map((e) => e.id),
                  ],
                ),
              );
            },
            icon: Icon(Icons.start),
          ),
        ],
      ),
      body: ListView(
        children: [
          Text(
            'Adjust the scaling so that this text is comfortable to read at 50cm away',
          ),
        ],
      ),
    );
  }
}
