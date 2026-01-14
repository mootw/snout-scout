import 'package:app/battle_pass/unlocks.dart';
import 'package:app/providers/data_provider.dart';
import 'package:app/screens/scout_authenticator_dialog.dart';
import 'package:app/widgets/scout_name_display.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:snout_db/action.dart';
import 'package:snout_db/actions/extras/write_scout_profile.dart';
import 'package:snout_db/app_extras/scout_profile.dart';
import 'package:snout_db/message.dart';
import 'package:snout_db/pubkey.dart';
import 'package:snout_db/snout_chain.dart';

// https://regex101.com/r/Y1UQsG/1
// https://www.unicode.org/Public/emoji/latest/emoji-test.txt

RegExp emojiMatch = RegExp(
  // This regex is so cursed that the dart lints think it is invalid
  // ignore: valid_regexps
  r'((?![\u{23}-\u1F6F3]([^\u{FE0F}]|$))\p{Emoji}(?:(?!\u{200D})\p{EComp}|(?=\u{200D})\u{200D}\p{Emoji})*)',
  multiLine: true,
  unicode: true,
);

class EditScoutProfile extends StatefulWidget {
  const EditScoutProfile({super.key, required this.scoutPubkey});

  final Pubkey scoutPubkey;

  @override
  State<EditScoutProfile> createState() => _EditScoutProfileState();
}

class _EditScoutProfileState extends State<EditScoutProfile> {
  List<Unlock> _selectedUnlocks = [];

  final _formKey = GlobalKey<FormState>();

  final _prefixEmojiController = TextEditingController();
  final _suffixEmojiController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final db = context.read<DataProvider>().database;
    ScoutProfile? profile = db.scoutProfiles[widget.scoutPubkey];

    profile ??= ScoutProfile();
    _prefixEmojiController.text = profile.prefixEmoji;
    _suffixEmojiController.text = profile.suffixEmoji;
    _selectedUnlocks = allPossibleUnlocks()
        .where((unlock) => profile!.selectedUpgrades.contains(unlock.id))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final db = context.watch<DataProvider>().database;

    final unlockedRewards = _getUnlockedRewards(widget.scoutPubkey, db);

    final int maxPrefixLength = _selectedUnlocks.fold(
      0,
      (v, e) => e is EmojiPrefixUnlock
          ? e.quantity > v
                ? e.quantity
                : v
          : v,
    );
    final int maxSuffixLength = _selectedUnlocks.fold(
      0,
      (v, e) => e is EmojiSuffixUnlock
          ? e.quantity > v
                ? e.quantity
                : v
          : v,
    );

    return Scaffold(
      appBar: AppBar(title: Text('Edit Profile')),
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: ListView(
          padding: EdgeInsets.only(left: 16, right: 16),
          children: [
            Text('Preview:'),
            ScoutName(
              db: db,
              scoutPubkey: widget.scoutPubkey,
              unlockOverride: _selectedUnlocks,
              profileOverride: ScoutProfile(
                selectedUpgrades: _selectedUnlocks.map((e) => e.id).toList(),
                prefixEmoji: _prefixEmojiController.text,
                suffixEmoji: _suffixEmojiController.text,
              ),
            ),
            SizedBox(height: 16),

            Text('Unlocked Items:'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final reward in unlockedRewards)
                  ChoiceChip(
                    label: Text(reward.name),
                    selected: _selectedUnlocks.contains(reward),
                    onSelected: (value) {
                      setState(() {
                        if (value) {
                          _selectedUnlocks.add(reward);
                        } else {
                          _selectedUnlocks.remove(reward);
                        }
                      });
                    },
                  ),
              ],
            ),

            SizedBox(height: 8),
            if (_selectedUnlocks.any((e) => e is EmojiPrefixUnlock)) ...[
              SizedBox(
                width: 150,
                child: TextFormField(
                  controller: _prefixEmojiController,
                  maxLength: maxPrefixLength,
                  validator: (value) {
                    if (value != null) {
                      final matches = emojiMatch.allMatches(value);
                      if (value.replaceAll(emojiMatch, '').isNotEmpty) {
                        return 'Only emojis allowed';
                      }

                      if (matches.length > maxPrefixLength) {
                        return '$maxPrefixLength emoji allowed';
                      }
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    label: Text('Prefix Emoji'),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
            ],
            SizedBox(height: 8),
            if (_selectedUnlocks.any((e) => e is EmojiSuffixUnlock)) ...[
              SizedBox(
                width: 150,
                child: TextFormField(
                  controller: _suffixEmojiController,
                  maxLength: maxSuffixLength,
                  validator: (value) {
                    if (value != null) {
                      final matches = emojiMatch.allMatches(value);
                      if (value.replaceAll(emojiMatch, '').isNotEmpty) {
                        return 'Only emojis allowed';
                      }

                      if (matches.length > maxSuffixLength) {
                        return '$maxSuffixLength emoji allowed';
                      }
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    label: Text('Suffix Emoji'),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
            ],

            SizedBox(height: 16),
            FilledButton(
              onPressed: () async {
                if (_formKey.currentState!.validate() == false) {
                  return;
                }
                // Save profile
                final newProfile = ScoutProfile(
                  selectedUpgrades: _selectedUnlocks.map((e) => e.id).toList(),
                  prefixEmoji: _prefixEmojiController.text,
                  suffixEmoji: _suffixEmojiController.text,
                );

                final AuthorizedScoutData? auth = await showDialog(
                  context: context,
                  builder: (context) => ScoutAuthorizationDialog(
                    allowBackButton: true,
                    scoutToAuthorize: widget.scoutPubkey,
                  ),
                );

                if (auth == null) {
                  return;
                }

                List<int> lastHash = await db.actions.last.hash;

                SignedChainMessage signed = await ChainActionData(
                  time: DateTime.now(),
                  previousHash: lastHash,
                  action: ActionWriteScoutProfile(newProfile),
                ).encodeAndSign(auth.secretKey);

                if (!context.mounted) {
                  return;
                }

                await context.read<DataProvider>().newTransaction(signed);
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Save Profile'),
            ),
          ],
        ),
      ),
    );
  }
}

List<Unlock> _getUnlockedRewards(Pubkey scoutPubkey, SnoutChain db) {
  final battlePassLevel = db.scoutBattlePassLevels[scoutPubkey] ?? 0;
  return battlePassRewards.entries
      .where((e) => e.key <= battlePassLevel)
      .map((e) => e.value)
      .expand((rewards) => rewards)
      .toList();
}
