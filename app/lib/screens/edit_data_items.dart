import 'package:app/data_submit_login.dart';
import 'package:app/edit_lock.dart';
import 'package:app/providers/data_provider.dart';
import 'package:app/widgets/confirm_exit_dialog.dart';
import 'package:app/widgets/dynamic_property_editor.dart';
import 'package:app/widgets/load_status_or_error_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:snout_db/actions/write_dataitem.dart';
import 'package:snout_db/config/data_item_schema.dart';
import 'package:snout_db/data_item.dart';
import 'package:snout_db/event/dynamic_property.dart';

// TODO make the page not drop before showing the auth dialog
Future editTeamDataPage(BuildContext context, int team) async {
  final data = context.read<DataProvider>();

  final List<MapEntry>? result = await navigateWithEditLock(
    context,
    "scoutteam:$team",
    (context) => Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditDataItemsPage(
          title: Text("Scouting $team"),
          config: data.event.config.pitscouting,
          initialData: data.event.pitscouting[team.toString()],
        ),
      ),
    ),
  );

  if (context.mounted && result != null) {
    await submitMultipleActions(
      context,
      result
          .map((e) => ActionWriteDataItem(DataItem.team(team, e.key, e.value)))
          .toList(),
    );
  }
}

Future editMatchDataPage(BuildContext context, String matchID) async {
  final snoutData = context.read<DataProvider>();

  final List<MapEntry>? result = await navigateWithEditLock(
    context,
    "matchdata:$matchID",
    (context) => Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditDataItemsPage(
          title: Text('Match $matchID'),
          config: snoutData.event.config.matchscouting.properties,
          initialData: snoutData.event.matchProperties(matchID),
        ),
      ),
    ),
  );

  if (context.mounted && result != null) {
    await submitMultipleActions(
      context,
      result
          .map(
            (e) => ActionWriteDataItem(DataItem.match(matchID, e.key, e.value)),
          )
          .toList(),
    );
  }
}

Future editPitData(BuildContext context) async {
  final snoutData = context.read<DataProvider>();

  final List<MapEntry>? result = await navigateWithEditLock(
    context,
    "pitdata",
    (context) => Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditDataItemsPage(
          title: const Text('Pit Data'),
          config: snoutData.event.config.pit,
          initialData: DynamicProperties.fromEntries(
            snoutData.event.dataItems.entries
                .where(
                  // TODO use a more robust way to identify the values for this robots survey using a proper index based on the config
                  (e) => e.key.startsWith('/pit/'),
                )
                .map((e) => MapEntry(e.value.$1.key, e.value.$1.value))
                .toList(),
          ),
        ),
      ),
    ),
  );

  if (context.mounted && result != null) {
    await submitMultipleActions(
      context,
      result
          .map((e) => ActionWriteDataItem(DataItem.pit(e.key, e.value)))
          .toList(),
    );
  }
}

class EditDataItemsPage extends StatefulWidget {
  final List<DataItemSchema> config;
  final DynamicProperties? initialData;
  final Widget title;

  const EditDataItemsPage({
    super.key,
    required this.config,
    required this.title,
    this.initialData,
  });

  @override
  State<EditDataItemsPage> createState() => _EditDataItemsPageState();
}

class _EditDataItemsPageState extends State<EditDataItemsPage> {
  final DynamicProperties _items = {};
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();

    //populate existing data to pre-fill.
    if (widget.initialData != null) {
      _items.addAll(widget.initialData!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ConfirmExitDialog(
      child: Scaffold(
        appBar: AppBar(
          title: widget.title,
          bottom: const LoadOrErrorStatusBar(),
          actions: [
            IconButton(
              onPressed: () async {
                if (_formKey.currentState!.validate() == false) {
                  //There are form errors, do nothing here.
                  return;
                }

                //New map instance to avoid messing up the UI
                final onlyChanges = Map.of(_items).entries
                    .where(
                      (entry) => widget.initialData?[entry.key] != entry.value,
                    )
                    .toList();

                if (context.mounted) {
                  Navigator.pop(context, onlyChanges);
                }
              },
              icon: const Icon(Icons.save),
            ),
          ],
        ),
        body: Form(
          autovalidateMode: AutovalidateMode.onUserInteraction,
          key: _formKey,
          child: ListView(
            children: [
              for (final item in widget.config)
                Container(
                  padding: const EdgeInsets.all(12),
                  child: DynamicPropertyEditorWidget(
                    tool: item,
                    survey: _items,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
