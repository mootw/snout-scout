import 'dart:convert';
import 'dart:typed_data';

import 'package:app/providers/data_provider.dart';
import 'package:app/providers/identity_provider.dart';
import 'package:app/widgets/scout_name_display.dart';
import 'package:collection/collection.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snout_db/action.dart';
import 'package:snout_db/actions/add_keypair.dart';
import 'package:snout_db/crypto.dart';
import 'package:snout_db/pubkey.dart';
import 'package:snout_db/snout_chain.dart';

import 'package:webcrypto/webcrypto.dart';

List<Pubkey> getAllKnownIdentities(SnoutChain database) =>
    database.allowedKeys.keys.toList();

typedef AuthorizedScoutData = ({List<int> secretKey, Pubkey pubkey});

class ScoutAuthorizationDialog extends StatefulWidget {
  const ScoutAuthorizationDialog({
    super.key,
    required this.allowBackButton,
    this.scoutToAuthorize,
  });

  final Pubkey? scoutToAuthorize;
  final bool allowBackButton;

  @override
  State<ScoutAuthorizationDialog> createState() =>
      _ScoutAuthorizationDialogState();
}

class _ScoutAuthorizationDialogState extends State<ScoutAuthorizationDialog> {
  Pubkey? _selectedScout;
  String? _errorText;
  final _scoutPassword = TextEditingController();

  @override
  void initState() {
    super.initState();

    _selectedScout = widget.scoutToAuthorize;

    if (_selectedScout == null) {
      () async {
        final prefs = await SharedPreferences.getInstance();
        final lastSelectedScout = prefs.getString('_lastSelectedScout');

        if (lastSelectedScout != null) {
          setState(() {
            _selectedScout = Pubkey(base64Decode(lastSelectedScout));
          });
        }
      }();
    }
  }

  // Sets the last used scout name before returning the result.
  Future _popWithScout(AuthorizedScoutData scout) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('_lastSelectedScout', base64Encode(scout.pubkey.bytes));
    if (mounted) {
      final identityProvider = context.read<IdentityProvider>();
      await identityProvider.setIdentity(scout.pubkey);
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
        title: Text(Uri.decodeFull(dp.dataSourceUri.toString())),
      ),
      body: Padding(
        padding: const EdgeInsets.only(left: 12, right: 12, bottom: 8),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Wrap(
                  clipBehavior: Clip.hardEdge,
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    for (final identity
                        in widget.scoutToAuthorize != null
                            ? [widget.scoutToAuthorize!]
                            : allKnownIdentities)
                      ChoiceChip(
                        visualDensity: VisualDensity.compact,
                        selected: _selectedScout == identity,
                        label: ScoutName(db: database, scoutPubkey: identity),
                        onSelected: (_) {
                          setState(() {
                            _selectedScout = identity;
                          });
                        },
                      ),
                    if (widget.scoutToAuthorize == null)
                      ActionChip(
                        visualDensity: VisualDensity.compact,
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add, size: 16),
                            Text('Register'),
                          ],
                        ),
                        onPressed: () async {
                          final auth = await registerNewScout(context);
                          if (auth != null && context.mounted) {
                            _popWithScout(auth);
                          }
                        },
                      ),
                  ],
                ),
              ),
            ),

            Center(
              child: SizedBox(
                width: 150,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Password',
                    errorText: _errorText,
                  ),
                  obscureText: true,
                  onEditingComplete: () => attemptLogin(database),
                  controller: _scoutPassword,
                ),
              ),
            ),
            SizedBox(height: 16),
            SizedBox(
              width: 200,
              height: 270,
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
                    child: Icon(Icons.delete, size: 16),
                  ),
                  FilledButton.tonal(
                    onPressed: () {
                      _scoutPassword.text += '0';
                    },
                    child: Text('0'),
                  ),
                  FilledButton(
                    onPressed: () => attemptLogin(database),
                    child: Icon(Icons.check, size: 16),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void attemptLogin(SnoutChain database) async {
    try {
      final result = await decryptSeedKey(
        seedKey: database.allowedKeys[_selectedScout]!,
        password: utf8.encode(_scoutPassword.text),
      );
      _popWithScout((pubkey: _selectedScout!, secretKey: result));
    } catch (e, s) {
      setState(() {
        _scoutPassword.text = '';
        _errorText = 'Decryption failed';
      });
      print('Decryption failed: $e');
      print(s);
    }
  }
}

// Registers a new scout and returns the authorization data for that scout
Future<AuthorizedScoutData?> registerNewScout(BuildContext context) async {
  final database = context.read<DataProvider>().database;
  final RegistrationResult? dialogResult = await showDialog(
    context: context,
    builder: (context) => const ScoutRegistrationScreen(),
  );
  final rootUser = database.actions.firstWhereOrNull(
    (e) => e.payload.action is ActionWriteKeyPair,
  );

  if (rootUser == null) {
    throw Exception('No root user found in database');
  }

  if (dialogResult != null && context.mounted) {
    final AuthorizedScoutData? auth = await showDialog(
      context: context,
      builder: (context) => ScoutAuthorizationDialog(
        allowBackButton: true,
        scoutToAuthorize: rootUser.author,
      ),
    );

    if (auth != null) {
      final signed = await ChainActionData(
        time: DateTime.now(),
        previousHash: await database.actions.last.hash,
        action: dialogResult.$2,
      ).encodeAndSign(auth.secretKey as Uint8List);

      // Submit a patch for adding the new scout
      final dataProvider = context.read<DataProvider>();
      await dataProvider.newTransaction(signed);

      // Patch has been submitted, now pop with the new scouts authorization
      return (secretKey: dialogResult.$1, pubkey: dialogResult.$2.pk);
    }
  }
  return null;
}

typedef RegistrationResult = (List<int> seed, ActionWriteKeyPair addKey);

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
                  if ((input?.runes.length ?? 0) > 16) {
                    return 'Name must be <= 16 characters';
                  }
                  RegExp exp = RegExp(r'^[a-zA-Z0-9_]+$');
                  if (!exp.hasMatch(input ?? '')) {
                    return 'Name can only contain letters, numbers, and underscores';
                  }
                  return null;
                },
                maxLines: 1,
                maxLength: 16,
                controller: _scoutNameText,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextFormField(
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(hintText: 'Password'),
                obscureText: true,
                validator: (input) =>
                    (input?.runes.length ?? 0) == 4 &&
                        int.tryParse(input ?? '') != null
                    ? null
                    : 'Invalid Password. requires exactly 4 digits',
                controller: _scoutPassword,
              ),
            ),
            Center(
              child: _isLoading
                  ? CircularProgressIndicator()
                  : FilledButton(
                      onPressed: _formKey.currentState?.validate() == true
                          ? () async {
                              setState(() {
                                _isLoading = true;
                              });
                              await Future.delayed(Duration.zero);

                              final seed = Uint8List(32);
                              fillRandomBytes(seed);

                              final encryptedKey = await encryptSeedKey(
                                seedKey: seed,
                                password: utf8.encode(_scoutPassword.text),
                              );

                              final keypair = await Ed25519()
                                  .newKeyPairFromSeed(seed);

                              final pubkey = await keypair
                                  .extractPublicKey()
                                  .then((value) => Pubkey(value.bytes));

                              // Create a patch that adds this scout
                              String alias = _scoutNameText.text;

                              final addKey = ActionWriteKeyPair(
                                encryptedKey,
                                pubkey,
                                alias,
                              );

                              setState(() {
                                _isLoading = false;
                              });
                              if (mounted && context.mounted) {
                                Navigator.pop(context, (seed, addKey));
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
