import 'dart:convert';

import 'package:cbor/cbor.dart';
import 'package:snout_db/action.dart';
import 'package:snout_db/message.dart';
import 'package:snout_db/snout_chain.dart';

class ActionWriteConfig implements ChainAction {
  static const int typeId = 20;
  @override
  int get id => typeId;

  final EventConfig config;

  ActionWriteConfig(this.config);

  @override
  CborValue toCbor() => CborMap({
    CborString("config"): CborString(json.encode(config.toJson())),
  });

  factory ActionWriteConfig.fromCbor(CborValue data) {
    final map = data as CborMap;
    return ActionWriteConfig(
      EventConfig.fromJson(
        json.decode((map[CborString("config")]! as CborString).toString())
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
    chain.event.config = config;
  }
}
