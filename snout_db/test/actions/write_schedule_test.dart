import 'package:snout_db/action.dart';
import 'package:snout_db/actions/write_schedule.dart';
import 'package:snout_db/event/match_schedule_item.dart';
import 'package:snout_db/snout_chain.dart';
import 'package:test/test.dart';

import '../keypair.dart';

void main() async {
  final keyPair = await testGenKey();
  final rootKeypairAction = await testGetKeyPairAction(pair: keyPair);

  test('write empty Schedule', () async {
    final db = SnoutChain([rootKeypairAction]);

    final writeConfigAction = await ChainActionData(
      time: DateTime.now(),
      previousHash: await rootKeypairAction.hash,
      action: ActionWriteSchedule([]),
    ).encodeAndSign(await keyPair.extractPrivateKeyBytes());

    await db.verifyApplyAction(writeConfigAction);

    expect(db.event.schedule.isEmpty, equals(true));
  });

  test('write Schedule', () async {
    final db = SnoutChain([rootKeypairAction]);

    final writeConfigAction = await ChainActionData(
      time: DateTime.now(),
      previousHash: await rootKeypairAction.hash,
      action: ActionWriteSchedule([
        MatchScheduleItem(
          id: 'p1',
          label: 'Practice 1',
          scheduledTime: DateTime.now(),
          red: const [6749],
          blue: const [6749],
        ),
      ]),
    ).encodeAndSign(await keyPair.extractPrivateKeyBytes());

    await db.verifyApplyAction(writeConfigAction);

    print(db.event.schedule);

    expect(db.event.schedule.containsKey('p1'), equals(true));
  });
}
