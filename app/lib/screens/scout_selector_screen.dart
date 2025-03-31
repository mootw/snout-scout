import 'dart:convert';

import 'package:app/providers/data_provider.dart';
import 'package:app/providers/identity_provider.dart';
import 'package:app/screens/select_data_source.dart';
import 'package:flutter/material.dart';
import 'package:hashlib/hashlib.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snout_db/patch.dart';
import 'package:snout_db/snout_db.dart';

import 'dart:math' as math;

List<String> getAllKnownIdentities(SnoutDB database) =>
    database.event.scoutPasswords.keys.toList();

class ScoutSelectorScreen extends StatefulWidget {
  const ScoutSelectorScreen({super.key, required this.allowBackButton});

  final bool allowBackButton;

  @override
  State<ScoutSelectorScreen> createState() => _ScoutSelectorScreenState();
}

class _ScoutSelectorScreenState extends State<ScoutSelectorScreen> {
  String? _selectedScout;
  final _scoutPassword = TextEditingController();

  @override
  void initState() {
    super.initState();

    () async {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _selectedScout = prefs.getString('_lastSelectedScout');
      });
    }();
  }

  // Sets the last used scout name before returning the result.
  Future _popWithScout(String scout) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('_lastSelectedScout', scout);
    if (mounted) {
      final identityProvider = context.read<IdentityProvider>();
      await identityProvider.setIdentity(scout);
    }
    // Checks if the route is the lowest route. To avoid popping the main route on the home screen
    if (mounted && Navigator.canPop(context)) {
      Navigator.pop(context, scout);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dp = context.watch<DataProvider>();
    final database = dp.database;

    final allKnownIdentities = getAllKnownIdentities(database);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: widget.allowBackButton,
        actions: [
          TextButton(
            onPressed:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => SelectDataSourceScreen()),
                ),
            child: Text("Change Source"),
          ),
        ],
        title: Text(Uri.decodeFull(dp.dataSourceUri.toString())),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            FilledButton.tonal(
              child: const Text('Register Scout'),
              onPressed: () async {
                final String? dialogResult = await showDialog(
                  context: context,
                  builder: (context) => const ScoutRegistrationScreen(),
                );

                if (dialogResult != null) {
                  _popWithScout(dialogResult);
                }
              },
            ),
            Expanded(child: SizedBox()),
            SizedBox(
              width: 800,
              child: Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  for (final identity in allKnownIdentities)
                    ChoiceChip(
                      selected: _selectedScout == identity,
                      label: Text(identity),
                      onSelected: (_) {
                        setState(() {
                          _selectedScout = identity;
                        });
                      },
                    ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 150,
                  child: TextField(
                    decoration: const InputDecoration(hintText: 'Password'),
                    obscureText: true,
                    onEditingComplete: () => attemptLogin(database),
                    controller: _scoutPassword,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            SizedBox(
              width: 220,
              height: 300,
              child: GridView.count(
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                crossAxisCount: 3,
                children: [
                  for (int i = 1; i < 10; i++)
                    FilledButton.tonal(
                      onPressed: () {
                        _scoutPassword.text += '$i';
                      },
                      child: Text('$i'),
                    ),
                  // Empty spot
                  FilledButton.tonal(
                    onPressed: () {
                      _scoutPassword.text = '';
                    },
                    child: Icon(Icons.delete),
                  ),
                  FilledButton.tonal(
                    onPressed: () {
                      _scoutPassword.text += '0';
                    },
                    child: Text('0'),
                  ),
                  FilledButton(
                    onPressed: () => attemptLogin(database),
                    child: Icon(Icons.check),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void attemptLogin(SnoutDB database) {
    final validPassword = argon2Verify(
      database.event.scoutPasswords[_selectedScout]!,
      utf8.encode(_scoutPassword.text),
    );

    if (validPassword) {
      _popWithScout(_selectedScout!);
    } else {
      // Clear text field
      setState(() {
        _scoutPassword.text = '';
      });
    }
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

  final _scoutPassword = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final dataProvider = context.read<DataProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Register New Scout')),
      body: Form(
        autovalidateMode: AutovalidateMode.onUserInteraction,
        key: _formKey,
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextFormField(
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(hintText: 'Scout Name'),
                validator: (input) {
                  if ((input?.runes.length ?? 0) < 3) {
                    return 'Name must be >= 3 characters';
                  }
                  if (getAllKnownIdentities(
                    dataProvider.database,
                  ).contains(input)) {
                    return 'Name must be unique';
                  }
                  return null;
                },
                maxLines: 1,
                maxLength: 20,
                controller: _scoutNameText,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextFormField(
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(hintText: 'Password'),
                obscureText: true,
                validator:
                    (input) =>
                        (input?.runes.length ?? 0) == 4 &&
                                int.tryParse(input ?? '') != null
                            ? null
                            : 'Invalid Password. requires exactly 4 digits',
                controller: _scoutPassword,
              ),
            ),
            Center(
              child:
                  _isLoading
                      ? CircularProgressIndicator()
                      : FilledButton(
                        onPressed:
                            _formKey.currentState?.validate() == true
                                ? () async {
                                  setState(() {
                                    _isLoading = true;
                                  });
                                  await Future.delayed(Duration.zero);
                                  final random = math.Random.secure();
                                  final salt = [
                                    for (int i = 0; i < 16; i++)
                                      random.nextInt(256),
                                  ];

                                  final password = argon2id(
                                    utf8.encode(_scoutPassword.text),
                                    salt,
                                    hashLength: 16,
                                    security: Argon2Security.little,
                                  );

                                  // Create a patch that adds this scout
                                  String identity = _scoutNameText.text;

                                  Patch patch = Patch(
                                    identity: identity,
                                    time: DateTime.now(),
                                    path: Patch.buildPath([
                                      'scoutPasswords',
                                      identity,
                                    ]),
                                    value: password.encoded(),
                                  );

                                  await dataProvider.newTransaction(patch);

                                  setState(() {
                                    _isLoading = false;
                                  });
                                  if (mounted) {
                                    Navigator.pop(context, _scoutNameText.text);
                                  }
                                }
                                : null,
                        child: const Text('Register Scout'),
                      ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
