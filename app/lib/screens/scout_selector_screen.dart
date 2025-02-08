import 'package:app/screens/select_data_source.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snout_db/snout_db.dart';

class ScoutSelectorScreen extends StatefulWidget {
  final SnoutDB database;

  const ScoutSelectorScreen({required this.database, super.key});

  @override
  State<ScoutSelectorScreen> createState() => _ScoutSelectorScreenState();
}

class _ScoutSelectorScreenState extends State<ScoutSelectorScreen> {
  final _scoutNameText = TextEditingController(text: 'Scout Name');

  String? _lastSelectedScout;

  @override
  void initState() {
    super.initState();

    () async {
      final prefs = await SharedPreferences.getInstance();
      _lastSelectedScout = prefs.getString('_lastSelectedScout');
    }();
  }

  // Sets the last used scout name before returning the result.
  Future _popWithScout(String scout) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('_lastSelectedScout', scout);
    if (mounted) {
      Navigator.pop(context, scout);
    }
  }

  @override
  Widget build(BuildContext context) {
    final allCurrentIdentities = widget.database.patches
        .fold<List<String>>([], (a, b) => [...a, b.identity])
        .toSet()
        .sorted((a, b) => a.compareTo(b));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.database.event.config.name),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: FilledButton(
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SelectDataSourceScreen(),
                    )),
                child: const Text('Change Event')),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _scoutNameText,
                  ),
                ),
                TextButton(
                  onPressed: () => _popWithScout(_scoutNameText.text),
                  child: const Text('Register Scout'),
                ),
              ],
            ),
            const SizedBox(
              height: 16,
            ),
            SizedBox(
              width: 800,
              child: Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  for (final identity in allCurrentIdentities)
                    ActionChip(
                      autofocus: _lastSelectedScout == identity,
                      label: Text(identity),
                      onPressed: () => _popWithScout(identity),
                    ),
                ],
              ),
            ),
            FilledButton(
              child: const Text('Read Only'),
              onPressed: () => _popWithScout('readonly'),
            ),
          ],
        ),
      ),
    );
  }
}
