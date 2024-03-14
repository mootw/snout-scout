import 'package:app/providers/identity_provider.dart';
import 'package:app/widgets/confirm_exit_dialog.dart';
import 'package:app/providers/data_provider.dart';
import 'package:app/widgets/scouting_tool.dart';
import 'package:app/widgets/load_status_or_error_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:snout_db/config/eventconfig.dart';
import 'package:snout_db/event/pitscoutresult.dart';
import 'package:snout_db/patch.dart';

class PitScoutTeamPage extends StatefulWidget {
  final int team;
  final EventConfig config;
  final PitScoutResult? initialData;

  const PitScoutTeamPage(
      {super.key, required this.team, required this.config, this.initialData});

  @override
  State<PitScoutTeamPage> createState() => _PitScoutTeamPageState();
}

class _PitScoutTeamPageState extends State<PitScoutTeamPage> {
  final PitScoutResult _surveyItems = {};
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
    context.read<DataProvider>().updateStatus(context, "Scouting team ${widget.team}");
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

                  final snoutData = context.read<DataProvider>();
                  final identity = context.read<IdentityProvider>().identity;

                  //New map instance to avoid messing up the UI
                  final onlyChanges = Map.of(_surveyItems);
                  onlyChanges.removeWhere(
                      (key, value) => widget.initialData?[key] == value);
                  for (final item in onlyChanges.entries) {
                    Patch patch = Patch(
                        identity: identity,
                        time: DateTime.now(),
                        path: Patch.buildPath(
                            ['pitscouting', widget.team.toString(), item.key]),
                        value: item.value);
                    //Save the scouting results to the server!!
                    await snoutData.submitPatch(patch);
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
              for (final item in widget.config.pitscouting)
                Container(
                    padding: const EdgeInsets.all(12),
                    child: ScoutingToolWidget(
                      tool: item,
                      survey: _surveyItems,
                    )),
            ],
          ),
        ),
      ),
    );
  }
}
