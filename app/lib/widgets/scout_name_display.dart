import 'package:flutter/material.dart';
import 'package:snout_db/pubkey.dart';
import 'package:snout_db/snout_chain.dart';

// Displays a scout's alias name in the UI
class ScoutName extends StatelessWidget {
  final SnoutChain db;
  final Pubkey scoutPubkey;

  const ScoutName({super.key, required this.db, required this.scoutPubkey});

  @override
  Widget build(BuildContext context) {
    final alias = db.aliases[scoutPubkey];
    return Tooltip(
      message: scoutPubkey.toString(),
      child: Text(alias != null ? '$alias' : scoutPubkey.toString()),
    );
  }
}
