import 'dart:convert';

import 'package:app/config_editor/edit_survey_item.dart';
import 'package:app/data_submit_login.dart';
import 'package:app/form_validators.dart';
import 'package:app/providers/data_provider.dart';
import 'package:app/providers/identity_provider.dart';
import 'package:app/screens/edit_markdown.dart';
import 'package:app/style.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import 'package:snout_db/config/surveyitem.dart';
import 'package:snout_db/patch.dart';
import 'package:snout_db/snout_db.dart';

class ConfigEditorPage extends StatefulWidget {
  final EventConfig initialState;

  const ConfigEditorPage({
    super.key,
    this.initialState = const EventConfig(name: '', team: 6749, fieldImage: ''),
  });

  @override
  State<ConfigEditorPage> createState() => _ConfigEditorPageState();
}

class _ConfigEditorPageState extends State<ConfigEditorPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _tbaEventId;
  late final TextEditingController _tbaSecretKey;
  late FieldStyle _fieldStyle;
  late final TextEditingController _team;

  late final List<SurveyItem> _pitscouting;

  @override
  void initState() {
    super.initState();
    // Deep copy the config (jank mode)
    final config = EventConfig.fromJson(widget.initialState.toJson());

    _nameController = TextEditingController(text: config.name);
    _tbaEventId = TextEditingController(text: config.tbaEventId);
    _tbaSecretKey = TextEditingController(text: config.tbaSecretKey);
    _team = TextEditingController(text: config.team.toString());
    _pitscouting = List.of(config.pitscouting);

    _fieldStyle = config.fieldStyle;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Form(
        key: _formKey,
        child: ListView(
          cacheExtent: 99999,
          padding: const EdgeInsets.only(left: 12, right: 12, top: 12),
          children: [
            ListTile(
              title: TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  label: Text('name'),
                  border: const OutlineInputBorder(),
                ),
              ),
            ),

            ListTile(
              title: TextFormField(
                controller: _tbaEventId,
                decoration: InputDecoration(
                  label: Text('tbaEventId'),
                  border: const OutlineInputBorder(),
                ),
              ),
            ),

            ListTile(
              title: TextFormField(
                controller: _tbaSecretKey,
                decoration: InputDecoration(
                  label: Text('tbaSecretKey'),
                  border: const OutlineInputBorder(),
                ),
              ),
            ),

            ListTile(
              title: DropdownButtonFormField(
                value: _fieldStyle,
                items: [
                  for (final value in FieldStyle.values)
                    DropdownMenuItem<FieldStyle>(
                      value: value,
                      child: Text(value.toString()),
                    ),
                ],
                onChanged:
                    (newValue) => setState(() {
                      _fieldStyle = newValue!;
                    }),
                decoration: InputDecoration(
                  label: Text('fieldStyle'),
                  border: const OutlineInputBorder(),
                ),
              ),
            ),

            ListTile(
              title: TextFormField(
                controller: _team,
                validator: checkIsInteger,
                decoration: InputDecoration(
                  label: Text('team'),
                  border: const OutlineInputBorder(),
                ),
              ),
            ),

            ListTile(title: Text('pitscouting')),
            for (final (idx, item) in _pitscouting.indexed) ...[
              Padding(
                padding: EdgeInsetsGeometry.only(
                  left: 12,
                  bottom: 12,
                ),
                child: ListTile(
                  title: Container(color: idx % 2 == 0 ? null : Colors.white12, child: EditSurveyItemConfig(config: item)),
                  trailing: IconButton(
                    onPressed: () => setState(() {
                      _pitscouting.removeAt(idx);
                    }),
                    icon: Icon(Icons.remove, color: Colors.redAccent),
                  ),
                ),
              ),
            ],
            Center(
              child: FilledButton.tonalIcon(
                onPressed:
                    () => setState(() {
                      _pitscouting.add(
                        SurveyItem(
                          id: '',
                          type: SurveyItemType.toggle,
                          label: '',
                        ),
                      );
                    }),
                label: Text('Add'),
                icon: Icon(Icons.add),
              ),
            ),
            
            // Text('matchscouting'),
            // Text('matchscouting.events'),
            // Text('matchscouting.processes'),
            // Text('matchscouting.survey'),
            // Text('matchscouting.properties'),
            ListTile(
              title: const Text("Edit Docs"),
              leading: const Icon(Icons.book),
              onTap: () async {
                final identity = context.read<IdentityProvider>().identity;
                final dataProvider = context.read<DataProvider>();
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => EditMarkdownPage(
                          source: dataProvider.event.config.docs,
                        ),
                  ),
                );
                if (result != null) {
                  Patch patch = Patch(
                    identity: identity,
                    time: DateTime.now(),
                    path: Patch.buildPath(['config', 'docs']),
                    value: result,
                  );
                  //Save the scouting results to the server!!
                  if (context.mounted) {
                    await submitData(context, patch);
                  }
                }
              },
            ),

            const SizedBox(height: 12),
            ListTile(
              title: const Text(
                "Set Field Image (2:1 ratio, blue alliance left, scoring table bottom)",
              ),
              leading: const Icon(Icons.map),
              onTap: () async {
                final identity = context.read<IdentityProvider>().identity;
                String result;
                try {
                  final bytes = await pickOrTakeImageDialog(
                    context,
                    largeImageSize,
                  );
                  if (bytes != null) {
                    result = base64Encode(bytes);
                    Patch patch = Patch(
                      identity: identity,
                      time: DateTime.now(),
                      path: Patch.buildPath(['config', 'fieldImage']),
                      value: result,
                    );
                    //Save the scouting results to the server!!
                    if (context.mounted) {
                      await submitData(context, patch);
                    }
                  }
                } catch (e, s) {
                  Logger.root.severe("Error taking image from device", e, s);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
