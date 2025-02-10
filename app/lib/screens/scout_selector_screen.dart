import 'package:app/providers/data_provider.dart';
import 'package:app/providers/loading_status_service.dart';
import 'package:app/screens/select_data_source.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ScoutSelectorScreen extends StatefulWidget {
  const ScoutSelectorScreen({super.key});

  @override
  State<ScoutSelectorScreen> createState() => _ScoutSelectorScreenState();
}

class _ScoutSelectorScreenState extends State<ScoutSelectorScreen> {
  String? _lastSelectedScout;

  @override
  void initState() {
    super.initState();

    () async {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _lastSelectedScout = prefs.getString('_lastSelectedScout');
      });
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
    final dp = context.watch<DataProvider>();
    final database = dp.database;

    bool isLoading = database.event.config.team == emptyNewEvent.config.team;

    final allKnownIdentities = database.patches
        .fold<List<String>>([], (a, b) => [...a, b.identity])
        .toSet()
        .sorted((a, b) => a.compareTo(b));

    return Scaffold(
      appBar: AppBar(
        title: Text(database.event.config.name),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FilledButton(
              child: const Text('New Scout'),
              onPressed: () async {
                final String? dialogResult = await showDialog(
                    context: context,
                    builder: (context) => const ScoutRegistrationScreen());

                if (dialogResult != null) {
                  _popWithScout(dialogResult);
                }
              },
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 800,
              child: Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  for (final identity in allKnownIdentities)
                    ActionChip(
                      autofocus: _lastSelectedScout == identity,
                      label: Text(identity),
                      onPressed: () => _popWithScout(identity),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Gets registration for a new scout profile
class ScoutRegistrationScreen extends StatefulWidget {
  const ScoutRegistrationScreen({super.key});

  @override
  State<ScoutRegistrationScreen> createState() =>
      _ScoutRegistrationScreenState();
}

class _ScoutRegistrationScreenState extends State<ScoutRegistrationScreen> {
  final _scoutNameText = TextEditingController();

  // final _scoutPassword = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register New Scout'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextFormField(
                decoration: const InputDecoration(
                  hintText: 'Scout Name',
                ),
                validator: (input) => (input?.runes.length ?? 0) >= 3
                    ? null
                    : 'Name must be >= 3 characters',
                maxLines: 1,
                maxLength: 20,
                controller: _scoutNameText,
              ),
            ),
            // Padding(
            //   padding: const EdgeInsets.all(16.0),
            //   child: TextFormField(
            //     onEditingComplete: () => _formKey.currentState!.validate(),
            //     decoration: const InputDecoration(
            //       hintText: 'Password',
            //     ),
            //     obscureText: true,
            //     validator: (input) => (input?.runes.length ?? 0) == 4 &&
            //             int.tryParse(input ?? '') != null
            //         ? null
            //         : 'Invalid Password. requires exactly 4 digits',
            //     controller: _scoutPassword,
            //   ),
            // ),
            Center(
              child: FilledButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    Navigator.pop(context, _scoutNameText.text);
                  }
                },
                child: const Text('Register Scout'),
              ),
            ),
            const SizedBox(
              height: 16,
            ),
          ],
        ),
      ),
    );
  }
}
