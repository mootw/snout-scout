import 'package:app/providers/identity_provider.dart';
import 'package:app/widgets/confirm_exit_dialog.dart';
import 'package:app/providers/data_provider.dart';
import 'package:app/widgets/dynamic_property_editor.dart';
import 'package:app/widgets/load_status_or_error_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:snout_db/config/surveyitem.dart';
import 'package:snout_db/event/dynamic_property.dart';
import 'package:snout_db/patch.dart';

//TODO this is basically an identical copy of the Scout Team Page but with some minor changes
//basically this should be converted to a single widget that has some sort of save function.
class EditMatchPropertiesPage extends StatefulWidget {
  final String matchID;
  final List<SurveyItem> config;
  final DynamicProperties? initialData;

  const EditMatchPropertiesPage(
      {super.key,
      required this.matchID,
      required this.config,
      this.initialData});

  @override
  State<EditMatchPropertiesPage> createState() =>
      _EditMatchPropertiesPageState();
}

class _EditMatchPropertiesPageState extends State<EditMatchPropertiesPage> {
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
    context
        .read<DataProvider>()
        .updateStatus(context, "Editing Match Properties");
    return ConfirmExitDialog(
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Match Properties"),
          bottom: const LoadOrErrorStatusBar(),
          actions: [
            IconButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate() == false) {
                    //There are form errors, do nothing here.
                    return;
                  }

                  final snoutData = context.read<DataProvider>();
                  final identity = context.read<IdentityProvider>().identity;

                  //New map instance to avoid messing up the UI
                  final onlyChanges = Map.of(_items);
                  onlyChanges.removeWhere(
                      (key, value) => widget.initialData?[key] == value);
                  for (final item in onlyChanges.entries) {
                    Patch patch = Patch(
                        identity: identity,
                        time: DateTime.now(),
                        path: Patch.buildPath([
                          'matches',
                          widget.matchID,
                          "properties",
                          item.key
                        ]),
                        value: item.value);
                    //Save the scouting results to the server!!
                    await snoutData.newTransaction(patch);
                  }
                  if (context.mounted) {
                    Navigator.of(context).pop(true);
                  }
                },
                icon: const Icon(Icons.save))
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
                    )),
            ],
          ),
        ),
      ),
    );
  }
}
