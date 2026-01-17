import 'dart:convert';

import 'package:cbor/cbor.dart';
import 'package:snout_db/action.dart';
import 'package:snout_db/event/match_schedule_item.dart';
import 'package:snout_db/message.dart';
import 'package:snout_db/snout_chain.dart';

/// Writes the event schedule. Since the schedule data is so small, we are okay with
/// not chunking it. This simplifies logic, and allows for pruning.
class ActionWriteSchedule implements ChainAction {
  static const int typeId = 23;
  @override
  int get id => typeId;

  final List<MatchScheduleItem> schedule;

  ActionWriteSchedule(this.schedule);

  @override
  CborValue toCbor() => CborMap({
    CborString("schedule"): CborString(
      json.encode(schedule.map((e) => e.toJson()).toList()),
    ),
  });

  factory ActionWriteSchedule.fromCbor(CborValue data) {
    final map = data as CborMap;
    return ActionWriteSchedule(
      (json.decode((map[CborString("schedule")]! as CborString).toString())
              as List<dynamic>)
          .map((e) => MatchScheduleItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  String? isValid(SnoutChain db, SignedChainMessage signee) {
    return null;
  }

  @override
  void apply(SnoutChain chain, SignedChainMessage signee) {
    chain.event.schedule = Map.fromEntries(
      schedule.map((e) => MapEntry(e.id, e)),
    );
  }
}
