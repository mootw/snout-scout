import 'package:app/providers/identity_provider.dart';
import 'package:app/widgets/confirm_exit_dialog.dart';
import 'package:app/providers/data_provider.dart';
import 'package:app/scouting_tools/scouting_tool.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:snout_db/config/eventconfig.dart';
import 'package:snout_db/event/pitscoutresult.dart';
import 'package:snout_db/patch.dart';

class PitScoutTeamPage extends StatefulWidget {
  final int team;
  final EventConfig config;
  final PitScoutResult? oldData;

  const PitScoutTeamPage(
      {super.key, required this.team, required this.config, this.oldData});

  @override
  State<PitScoutTeamPage> createState() => _PitScoutTeamPageState();
}

class _PitScoutTeamPageState extends State<PitScoutTeamPage> {
  final PitScoutResult _results = {};
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();

    //populate existing data to pre-fill.
    if (widget.oldData != null) {
      _results.addAll(widget.oldData!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ConfirmExitDialog(
      child: Scaffold(
        appBar: AppBar(
          actions: [
            IconButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate() == false) {
                    //There are form errors, do nothing here.
                    return;
                  }

                  //New map instance to avoid messing up the UI
                  final onlyChanges = Map.of(_results);

                  onlyChanges.removeWhere(
                      (key, value) => widget.oldData?[key] == value);

                  final snoutData = context.read<DataProvider>();

                  //TODO only submit items that changed, but for now we submit a patch for each item
                  for (final item in onlyChanges.entries) {
                    Patch patch = Patch(
                        identity: context.read<IdentityProvider>().identity,
                        time: DateTime.now(),
                        path: Patch.buildPath(
                            ['pitscouting', widget.team.toString(), item.key]),
                        value: item.value);
                    //Save the scouting results to the server!!
                    await snoutData.addPatch(patch);
                  }

                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Saving Scouting Data'),
                    duration: Duration(seconds: 4),
                  ));
                  if (mounted) {
                    Navigator.of(context).pop(true);
                  }
                },
                icon: const Icon(Icons.save))
          ],
          title: Text("Scouting ${widget.team}"),
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
                      survey: _results,
                    )),
            ],
          ),
        ),
      ),
    );
  }
}
