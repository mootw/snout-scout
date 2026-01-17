import 'package:animated_text_kit2/animated_text_kit2.dart';
import 'package:app/battle_pass/unlocks.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:snout_db/app_extras/scout_profile.dart';
import 'package:snout_db/pubkey.dart';
import 'package:snout_db/snout_chain.dart';

// Displays a scout's alias name in the UI
class ScoutName extends StatelessWidget {
  final SnoutChain db;
  final Pubkey scoutPubkey;
  final List<Unlock>? unlockOverride;
  final ScoutProfile? profileOverride;

  const ScoutName({
    super.key,
    required this.db,
    required this.scoutPubkey,
    this.unlockOverride,
    this.profileOverride,
  });

  @override
  Widget build(BuildContext context) {
    ScoutProfile profile =
        profileOverride ?? db.scoutProfiles[scoutPubkey] ?? ScoutProfile();

    // TODO validate profile unlocks are owned by scout
    List<Unlock> unlocks = allPossibleUnlocks()
        .where((unlock) => profile.selectedUpgrades.contains(unlock.id))
        .toList();
    if (unlockOverride != null) {
      unlocks = unlockOverride!;
    }

    final textColor =
        (unlocks.lastWhereOrNull((element) => element is NameColorUnlock)
                as NameColorUnlock?)
            ?.color;

    final underscore =
        (unlocks.lastWhereOrNull((element) => element is UnderscoreNameUnlock)
            as UnderscoreNameUnlock?);

    final bold =
        (unlocks.lastWhereOrNull((element) => element is BoldNameUnlock)
            as BoldNameUnlock?);

    final italic =
        (unlocks.lastWhereOrNull((element) => element is ItalicNameUnlock)
            as ItalicNameUnlock?);

    final rainbow =
        (unlocks.lastWhereOrNull((element) => element is RainbowNameUnlock)
            as RainbowNameUnlock?);

    final rgb =
        (unlocks.lastWhereOrNull((element) => element is RGBNameUnlock)
            as RGBNameUnlock?);

    // Only show prefix or suffix if they are enabled, not even bothering to validate length...
    final prefix =
        unlocks.lastWhereOrNull((element) => element is EmojiPrefixUnlock)
            as EmojiPrefixUnlock?;
    final suffix =
        unlocks.lastWhereOrNull((element) => element is EmojiSuffixUnlock)
            as EmojiSuffixUnlock?;

    final alias = db.aliases[scoutPubkey];
    final nameString = alias != null
        ? '${prefix == null ? '' : profile.prefixEmoji}$alias${suffix == null ? '' : profile.suffixEmoji}'
        : scoutPubkey.toString();

    final textStyle = TextStyle(
      color: textColor,
      decoration: underscore != null
          ? TextDecoration.underline
          : TextDecoration.none,
      fontWeight: bold != null ? FontWeight.bold : FontWeight.normal,
      fontStyle: italic != null ? FontStyle.italic : FontStyle.normal,
    );

    final banner =
        unlocks.lastWhereOrNull((element) => element is NameBannerUnlock)
            as NameBannerUnlock?;

    final aliasWidget = rainbow != null
        ? AnimatedTextKit2.Rainbow(
            repeat: true,
            text: nameString,
            duration: Duration(seconds: 9),
            textStyle: textStyle,
          )
        : rgb != null
        ? RGBText(text: Text(nameString, style: textStyle))
        : Text(nameString, style: textStyle);

    return Tooltip(
      message: scoutPubkey.toString(),
      child: banner?.containerBuilder(context, aliasWidget) ?? aliasWidget,
    );
  }
}

class RGBText extends StatefulWidget {
  final Text text;

  const RGBText({super.key, required this.text});

  @override
  State<RGBText> createState() => _RGBTextState();
}

class _RGBTextState extends State<RGBText> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this, // the SingleTickerProviderStateMixin
    );

    _controller.repeat(min: 0, max: 1, period: Duration(seconds: 9));
    _controller.addListener(() {
      setState(() {}); // This tells Flutter to rebuild the widget
    });
  }

  @override
  dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      widget.text.data!,
      style: widget.text.style?.copyWith(
        color: HSVColor.fromAHSV(1, _controller.value * 360, 1, 1).toColor(),
      ),
    );
  }
}
