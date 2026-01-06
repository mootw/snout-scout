import 'dart:convert';

import 'package:snout_db/app_extras/scout_profile.dart';
import 'package:snout_db/config/eventconfig.dart';
import 'package:snout_db/dbfile.dart';
import 'package:snout_db/event/frcevent.dart';
import 'package:snout_db/message.dart';
import 'package:snout_db/pubkey.dart';
import 'package:snout_db/secret_key.dart';
import 'package:snout_db/strategy/team_list.dart';

export 'package:snout_db/config/eventconfig.dart';
export 'package:snout_db/fieldposition.dart';
export 'package:snout_db/game.dart';
export 'dbfile.dart';

/// This is the in-memory representation of a SnoutDB chain, it is responsible for
/// parsing and building the decoded database chain and includes some higher
/// level features LIKE caching, index structures and other fancy DB related things
///
/// Entity <-> DataItem indexing occurs at the head of the chain, and is not strongly
/// enforced, so uploading a dataItem for a non-existant entity is possible and will
/// cause an orphaned dataItem. This is not a problem, and was a problem in the old DB design
class SnoutChain {
  /// Raw Chain content
  final List<SignedChainMessage> actions;

  /// -----------------------------------
  /// Indexes and cached data structures
  /// -----------------------------------

  /// public key data
  Map<Pubkey, EncryptedSecretKey> allowedKeys = {};

  /// Per scout name aliases
  Map<Pubkey, String> aliases = {};

  /// Per scout battle pass levels
  Map<Pubkey, int> scoutBattlePassLevels = {};

  /// Per scout configuration profile
  Map<Pubkey, ScoutProfile> scoutProfiles = {};

  /// Primary constructed data index
  FRCEvent event = FRCEvent(
    config: const EventConfig(
      name: 'Unnamed Event',
      team: 6749,
      fieldImage: '',
    ),
    matches: {},
  );

  // Note this constructor is unsafe as it does not check for valid chain rules!
  SnoutChain(this.actions) {
    if (actions.isEmpty) {
      print('Warning: initializing SnoutDB with empty action chain');
      return;
    }
    for (final message in actions) {
      final chainAction = message.payload;
      chainAction.action.apply(this, message);
    }

    // TODO create indexes
  }

  SnoutChain.fromFile(SnoutDBFile file) : actions = file.actions {
    for (final action in actions) {
      final chainAction = action.payload;
      chainAction.action.apply(this, action);
    }
  }

  /// Verifies that the given action can be performed on this database before adding it
  Future<void> verifyApplyAction(SignedChainMessage message) async {
    // Verify the author is in the allowedKeys
    if (actions.isNotEmpty) {
      // First action is always allowed as keys do not exist yet
      if (allowedKeys.keys.contains(message.author) == false) {
        throw Exception("Author key not in allowed keys");
      }
    }

    // Verify message signature, author is not who they claim to be
    if (await message.verify() == false) {
      throw Exception("Invalid message signature");
    }

    final chainAction = message.payload;

    /// Verify that this chain links to the previous message
    if (actions.isNotEmpty &&
        base64Encode(chainAction.previousHash) !=
            base64Encode(await actions.last.hash)) {
      print(
        'WARNING: Previous hash does not match last action hash, chain is broken',
      );
    }

    final valid = chainAction.action.isValid(this, message);
    if (valid == null) {
      // Adding the message to the db file must occur after applying the action
      // To ensure that actions depending on previous actions work correctly
      chainAction.action.apply(this, message);
      actions.add(message);

      // TODO update indexes
    } else {
      throw Exception("Action is not valid on this chain: $valid");
    }
  }
}
