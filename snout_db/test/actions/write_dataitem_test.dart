import 'package:snout_db/action.dart';
import 'package:snout_db/actions/write_dataitem.dart';
import 'package:snout_db/data_item.dart';
import 'package:snout_db/snout_chain.dart';
import 'package:test/test.dart';

import '../keypair.dart';

void main() async {
  final keyPair = await testGenKey();
  final rootKeypairAction = await testGetKeyPairAction(pair: keyPair);

  final dataItem = DataItem.team(6749, 'robot_name', 'Robert');

  test('add data item', () async {
    final db = SnoutChain([rootKeypairAction]);

    final writeConfigAction = await ChainActionData(
      time: DateTime.now(),
      previousHash: await rootKeypairAction.hash,
      action: ActionWriteDataItem(dataItem),
    ).encodeAndSign(await keyPair.extractPrivateKeyBytes());

    await db.verifyApplyAction(writeConfigAction);

    expect(db.event.dataItems, contains(dataItem.uniqueKey));
  });

  test('remove non-existant item', () async {
    final db = SnoutChain([rootKeypairAction]);

    final removeAction = await ChainActionData(
      time: DateTime.now(),
      previousHash: await rootKeypairAction.hash,
      action: ActionWriteDataItem(
        DataItem(dataItem.entity, dataItem.key, null),
      ),
    ).encodeAndSign(await keyPair.extractPrivateKeyBytes());

    await db.verifyApplyAction(removeAction);

    expect(db.event.dataItems, isNot(contains(dataItem.uniqueKey)));
  });

  test('remove data item', () async {
    final db = SnoutChain([rootKeypairAction]);

    final writeConfigAction = await ChainActionData(
      time: DateTime.now(),
      previousHash: await rootKeypairAction.hash,
      action: ActionWriteDataItem(dataItem),
    ).encodeAndSign(await keyPair.extractPrivateKeyBytes());

    final removeAction = await ChainActionData(
      time: DateTime.now(),
      previousHash: await writeConfigAction.hash,
      action: ActionWriteDataItem(
        DataItem(dataItem.entity, dataItem.key, null),
      ),
    ).encodeAndSign(await keyPair.extractPrivateKeyBytes());

    await db.verifyApplyAction(writeConfigAction);
    await db.verifyApplyAction(removeAction);

    expect(db.event.dataItems, isNot(contains(dataItem.uniqueKey)));
  });
}
