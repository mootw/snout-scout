import 'package:app/data_submit_login.dart';
import 'package:app/widgets/confirm_exit_dialog.dart';
import 'package:app/widgets/dynamic_property_editor.dart';
import 'package:app/widgets/load_status_or_error_bar.dart';
import 'package:flutter/material.dart';
import 'package:snout_db/config/surveyitem.dart';
import 'package:snout_db/event/dynamic_property.dart';
import 'package:snout_db/patch.dart';

class PitScoutTeamPage extends StatefulWidget {
  final int team;
  final List<SurveyItem> config;
  final DynamicProperties? initialData;

  const PitScoutTeamPage({
    super.key,
    required this.team,
    required this.config,
    this.initialData,
  });

  @override
  State<PitScoutTeamPage> createState() => _PitScoutTeamPageState();
}

class _PitScoutTeamPageState extends State<PitScoutTeamPage> {
  final DynamicProperties _surveyItems = {};
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();

    //populate existing data to pre-fill.
    if (widget.initialData != null) {
      _surveyItems.addAll(widget.initialData!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ConfirmExitDialog(
      child: Scaffold(
        appBar: AppBar(
          title: Text("Scouting ${widget.team}"),
          bottom: const LoadOrErrorStatusBar(),
          actions: [
            IconButton(
              onPressed: () async {
                if (_formKey.currentState!.validate() == false) {
                  //There are form errors, do nothing here.
                  return;
                }

                //New map instance to avoid messing up the UI
                final onlyChanges =
                    Map.of(_surveyItems).entries
                        .where(
                          (entry) =>
                              widget.initialData?[entry.key] != entry.value,
                        )
                        .toList();
                await submitMultiplePatches(
                  context,
                  onlyChanges
                      .map(
                        (e) => Patch.teamData(
                          DateTime.now(),
                          widget.team,
                          e.key,
                          e.value,
                        ),
                      )
                      .toList(),
                );
                if (context.mounted) {
                  Navigator.pop(context);
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
                    initialData: widget.initialData,
                    tool: item,
                    survey: _surveyItems,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
