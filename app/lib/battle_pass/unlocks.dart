import 'package:app/providers/data_provider.dart';
import 'package:app/providers/identity_provider.dart';
import 'package:app/widgets/scout_name_display.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:snout_db/app_extras/scout_profile.dart';

final battlePassRewards = <int, List<Unlock>>{
  1: [GreenName()],
  2: [EmojiSuffixUnlock('emoji-suffix-1', 1), RedName()],
  3: [MintVibesBanner(), BlueName()],
  4: [CyanName(), MagentaName()],
  5: [EmojiPrefixUnlock('emoji-prefix-1', 1), YellowName()],
  6: [PurpleVibesBanner(), ItalicNameUnlock()],
  7: [OrangeName(), TealName()],
  8: [EmojiSuffixUnlock('emoji-suffix-2', 2), PurpleName()],
  9: [CherryVibesBanner(), RGBNameUnlock()],
  10: [EmojiPrefixUnlock('emoji-prefix-2', 2), UnderscoreNameUnlock()],
  11: [BoldNameUnlock()],
  12: [RainbowNameUnlock()],
};

List<Unlock> allPossibleUnlocks() {
  return battlePassRewards.values.expand((e) => e).toSet().toList();
}

class PlaceholderUnlock extends Unlock {
  @override
  String id;

  PlaceholderUnlock(this.id);

  @override
  Widget buildPreview(BuildContext context) {
    return Text('Placeholder $id');
  }

  @override
  String get name => 'Placeholder Unlock $id';
}

class EmojiSuffixUnlock extends Unlock {
  @override
  String id;

  int quantity;

  EmojiSuffixUnlock(this.id, this.quantity);

  @override
  Widget buildPreview(BuildContext context) {
    final identity = context.read<IdentityProvider>().identity;

    if (identity == null) {
      return const Text('No identity selected');
    }

    return ScoutName(
      db: context.read<DataProvider>().database,
      scoutPubkey: identity,
      unlockOverride: [this],
      profileOverride: ScoutProfile(suffixEmoji: '⭐' * quantity),
    );
  }

  @override
  String get name => '$quantity Emoji Suffix';
}

class UnderscoreNameUnlock extends Unlock {
  @override
  String id = 'underscore-name';

  UnderscoreNameUnlock();

  @override
  String get name => 'Underscore Name';
}

class ItalicNameUnlock extends Unlock {
  @override
  String id = 'italic-name';

  ItalicNameUnlock();

  @override
  String get name => 'Italic Name';
}

class BoldNameUnlock extends Unlock {
  @override
  String id = 'bold-name';

  BoldNameUnlock();

  @override
  String get name => 'Bold Name';
}

class EmojiPrefixUnlock extends Unlock {
  @override
  String id;

  int quantity;

  EmojiPrefixUnlock(this.id, this.quantity);

  @override
  String get name => '$quantity Emoji Prefix';
  @override
  Widget buildPreview(BuildContext context) {
    final identity = context.read<IdentityProvider>().identity;

    if (identity == null) {
      return const Text('No identity selected');
    }

    return ScoutName(
      db: context.read<DataProvider>().database,
      scoutPubkey: identity,
      unlockOverride: [this],
      profileOverride: ScoutProfile(prefixEmoji: '⭐' * quantity),
    );
  }
}

class RedName extends NameColorUnlock {
  RedName() : super('name-red', 'Red', Colors.red);
}

class GreenName extends NameColorUnlock {
  GreenName() : super('name-green', 'Green', Colors.green);
}

class BlueName extends NameColorUnlock {
  BlueName() : super('name-blue', 'Blue', Colors.blue);
}

class CyanName extends NameColorUnlock {
  CyanName() : super('name-cyan', 'Cyan', Colors.cyan);
}

class MagentaName extends NameColorUnlock {
  MagentaName() : super('name-magenta', 'Magenta', Colors.pink);
}

class YellowName extends NameColorUnlock {
  YellowName() : super('name-yellow', 'Yellow', Colors.yellow);
}

class OrangeName extends NameColorUnlock {
  OrangeName() : super('name-orange', 'Orange', Colors.orange);
}

class TealName extends NameColorUnlock {
  TealName() : super('name-teal', 'Teal', Colors.teal);
}

class PurpleName extends NameColorUnlock {
  PurpleName() : super('name-purple', 'Purple', Colors.purple);
}

class NameColorUnlock extends Unlock {
  @override
  String id;

  String colorName;
  Color color;

  NameColorUnlock(this.id, this.colorName, this.color);

  @override
  String get name => '$colorName Name';
}

class MintVibesBanner extends NameBannerUnlock {
  MintVibesBanner()
    : super(
        'banner-mint-vibes',
        'Mint Vibes',
        (context, child) => DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            gradient: LinearGradient(
              colors: [
                Colors.greenAccent.withOpacity(0.3),
                Colors.cyanAccent.withOpacity(0.3),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: child,
          ),
        ),
      );
}

class PurpleVibesBanner extends NameBannerUnlock {
  PurpleVibesBanner()
    : super(
        'banner-purple-vibes',
        'Purple Vibes',
        (context, child) => DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            gradient: LinearGradient(
              colors: [
                Colors.purple.withOpacity(0.3),
                Colors.yellow.withOpacity(0.3),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: child,
          ),
        ),
      );
}

class CherryVibesBanner extends NameBannerUnlock {
  CherryVibesBanner()
    : super(
        'banner-cherry-vibes',
        'Cherry Vibes',
        (context, child) => DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            gradient: LinearGradient(
              colors: [
                Colors.redAccent.withOpacity(0.3),
                Colors.pinkAccent.withOpacity(0.3),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: child,
          ),
        ),
      );
}

class NameBannerUnlock extends Unlock {
  @override
  String id;
  @override
  String name;
  Function(BuildContext context, Widget child) containerBuilder;

  NameBannerUnlock(this.id, this.name, this.containerBuilder);
}

class RGBNameUnlock extends Unlock {
  @override
  String id = 'rgb-name';

  RGBNameUnlock();
  @override
  String get name => 'RGB Name';
}

class RainbowNameUnlock extends Unlock {
  @override
  String id = 'rainbow-name';

  RainbowNameUnlock();

  @override
  String get name => 'Rainbow Name';
}

abstract interface class Unlock {
  String get id;
  String get name;

  Widget buildPreview(BuildContext context) {
    final identity = context.read<IdentityProvider>().identity;

    if (identity == null) {
      return const Text('No identity selected');
    }

    return ScoutName(
      db: context.read<DataProvider>().database,
      scoutPubkey: identity,
      unlockOverride: [this],
    );
  }
}
