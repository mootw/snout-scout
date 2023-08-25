import 'package:app/providers/data_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:snout_db/patch.dart';

class EditAudit extends StatelessWidget {
  final List<String> path;

  const EditAudit({super.key, required this.path});

  @override
  Widget build(BuildContext context) {
    final item = context.watch<DataProvider>().database.getLastPatchFor(path);
    return Text(getAuditString(item) ?? '',
        style: Theme.of(context).textTheme.bodySmall!.copyWith(color: Theme.of(context).hintColor));
  }
}

String? getAuditString(Patch? item) => item == null
    ? null
    : '${item.identity} - ${DateFormat.jm().add_yMd().format(item.time)}';
