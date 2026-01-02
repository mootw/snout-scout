import 'dart:convert';

import 'package:cbor/cbor.dart';
import 'package:snout_db/action.dart';
import 'package:snout_db/app_extras/scout_profile.dart';
import 'package:snout_db/message.dart';
import 'package:snout_db/snout_chain.dart';

class ActionWriteScoutProfile implements ChainAction {
  static const int typeId = 901;

  @override
  int get id => typeId;

  ScoutProfile profile;

  ActionWriteScoutProfile(this.profile);

  @override
  CborValue toCbor() => CborMap({
    CborString("profile"): CborString(json.encode(profile.toJson())),
  });

  static ActionWriteScoutProfile fromCbor(CborValue data) {
    final map = data as CborMap;
    return ActionWriteScoutProfile(
      ScoutProfile.fromJson(
        json.decode((map[CborString("profile")]! as CborString).toString())
            as Map<String, dynamic>,
      ),
    );
  }

  @override
  String? isValid(SnoutChain db, SignedChainMessage signee) {
    return null;
  }

  @override
  void apply(SnoutChain chain, SignedChainMessage signee) {
    chain.scoutProfiles[signee.author] = profile;
  }
}
