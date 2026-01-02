import 'dart:convert';

import 'package:cbor/cbor.dart';
import 'package:collection/collection.dart';
import 'package:snout_db/action.dart';
import 'package:snout_db/message.dart';
import 'package:snout_db/snout_chain.dart';

class ActionWriteTeams implements ChainAction {
  static const int typeId = 21;
  @override
  int get id => typeId;

  final List<int> teams;

  ActionWriteTeams(this.teams);

  @override
  CborValue toCbor() =>
      CborMap({CborString("teams"): CborString(json.encode(teams))});

  static ActionWriteTeams fromCbor(CborValue data) {
    final map = data as CborMap;
    return ActionWriteTeams(
      List<int>.from(
        json.decode((map[CborString("teams")]! as CborString).toString())
            as List<dynamic>,
      ),
    );
  }

  @override
  String? isValid(SnoutChain db, SignedChainMessage signee) {
    /// The teams list is sorted from smallest to largest
    return teams.isSorted((a, b) => a.compareTo(b))
        ? null
        : "list is not sorted from smallest to largest";
  }

  @override
  void apply(SnoutChain chain, SignedChainMessage signee) {
    chain.event.teams = teams;
  }
}
