import 'package:app/kiosk/kiosk.dart';
import 'package:flutter/material.dart';
import 'package:snout_db/config/eventconfig.dart';
import 'package:snout_db/config/surveyitem.dart';

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
  Map<({Widget label, Widget subtitle, String id}), bool> _allowedIds = {};

  @override
  void initState() {
    super.initState();
    _allowedIds.addEntries(
      widget.baseConfig.pitscouting.map(
        (e) => MapEntry((
          label: Text(e.label),
          subtitle: Text('pitscouting.${e.id}'),
          id: e.id,
        ), e.type == SurveyItemType.text ? false : true),
      ),
    );
    _allowedIds.addEntries(
      widget.baseConfig.matchscouting.properties.map(
        (e) => MapEntry((
          label: Text(e.label),
          subtitle: Text('matchscouting.properties.${e.id}'),
          id: e.id,
        ), e.type == SurveyItemType.text ? false : true),
      ),
    );
    _allowedIds.addEntries(
      widget.baseConfig.matchscouting.processes.map(
        (e) => MapEntry((
          label: Text(e.label),
          subtitle: Text('process.${e.id}'),
          id: e.id,
        ), true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kiosk Settings'),
        actions: [
          IconButton(
            onPressed: () {
              runKiosk(
                widget.dataSource,
                KioskSettings(
                  safeIds:
                      _allowedIds.entries
                          .where((e) => e.value == true)
                          .map((e) => e.key.id)
                          .toList(),
                ),
              );
            },
            icon: Icon(Icons.start),
          ),
        ],
      ),
      body: ListView(
        children: [
          for (final id in _allowedIds.entries)
            Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 500),
                child: ListTile(
                  title: id.key.label,
                  subtitle: id.key.subtitle,
                  trailing: Switch(
                    value: id.value,
                    onChanged:
                        (newValue) => setState(() {
                          _allowedIds[id.key] = newValue;
                        }),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
