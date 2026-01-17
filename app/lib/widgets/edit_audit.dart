import 'package:app/providers/data_provider.dart';
import 'package:app/screens/chain_history.dart';
import 'package:app/widgets/datasheet.dart';
import 'package:app/widgets/scout_name_display.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:snout_db/data_item.dart';
import 'package:snout_db/pubkey.dart';
import 'package:snout_db/snout_chain.dart';

DataTableItem traceTableItem(SnoutChain db, String matchId, int team) {
  final key = '/match/$matchId/trace/$team';
  final result = db.event.traces[key];
  if (result == null) {
    return DataTableItem.fromText('');
  }
  final alias = db.aliases[result.$2] ?? result.$2.toString();
  return DataTableItem(
    displayValue: ScoutName(db: db, scoutPubkey: result.$2),
    exportValue: alias,
    sortingValue: alias,
  );
}

class DataItemEditAudit extends StatelessWidget {
  final DataItem dataItem;

  const DataItemEditAudit({super.key, required this.dataItem});

  @override
  Widget build(BuildContext context) {
    final db = context.watch<DataProvider>().database;

    final result = db.event.dataItems[dataItem.uniqueKey];

    if (result == null) {
      return SizedBox();
    }

    return EditAuditWidget(
      author: result.$2,
      db: db,
      filter: result.$1.uniqueKey,
      timestamp: result.$3,
    );
  }
}

class EditAuditWidget extends StatelessWidget {
  final Pubkey author;
  final DateTime timestamp;
  final String filter;
  final SnoutChain db;

  final bool compact;

  const EditAuditWidget({
    super.key,
    required this.author,
    required this.timestamp,
    required this.filter,
    required this.db,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ActionChainHistoryPage(filter: filter),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ScoutName(db: db, scoutPubkey: author),
          if (!compact)
            Text(
              ' - ${DateFormat.jm().add_yMd().format(timestamp)}',
              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                color: Theme.of(context).hintColor,
              ),
            ),
        ],
      ),
    );
  }
}
