import 'dart:convert';

import 'package:app/config_editor/edit_match_event.dart';
import 'package:app/config_editor/edit_process.dart';
import 'package:app/config_editor/edit_survey_item.dart';
import 'package:app/form_validators.dart';
import 'package:app/services/snout_image_cache.dart';
import 'package:app/style.dart';
import 'package:app/widgets/image_view.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:snout_db/config/matcheventconfig.dart';
import 'package:snout_db/config/matchresults_process.dart';
import 'package:snout_db/config/matchscouting.dart';
import 'package:snout_db/config/data_item_schema.dart';
import 'package:snout_db/snout_chain.dart';

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

  late final TextEditingController _name;
  late final TextEditingController _tbaEventId;
  late final TextEditingController _tbaSecretKey;
  late FieldStyle _fieldStyle;
  late final TextEditingController _team;
  late final List<SurveyItemEditState> _pit;
  late final List<SurveyItemEditState> _pitscouting;
  late final List<SurveyItemEditState> _matchscoutingSurvey;
  late final List<SurveyItemEditState> _matchscoutingProperties;
  late final List<MatchEventConfigEditState> _matchscoutingEvents;
  late final List<ProcessConfigEditState> _matchscoutingProcess;
  late String fieldImage;

  @override
  void initState() {
    super.initState();
    // Deep copy the config (jank mode)
    final config = EventConfig.fromJson(widget.initialState.toJson());

    _name = TextEditingController(text: config.name);
    _tbaEventId = TextEditingController(text: config.tbaEventId);
    _tbaSecretKey = TextEditingController(text: config.tbaSecretKey);
    _team = TextEditingController(text: config.team.toString());
    _pit = config.pit.map((item) => SurveyItemEditState(item)).toList();
    _pitscouting = config.pitscouting
        .map((item) => SurveyItemEditState(item))
        .toList();
    _matchscoutingSurvey = config.matchscouting.survey
        .map((item) => SurveyItemEditState(item))
        .toList();
    _matchscoutingProperties = config.matchscouting.properties
        .map((item) => SurveyItemEditState(item))
        .toList();

    _matchscoutingEvents = config.matchscouting.events
        .map((item) => MatchEventConfigEditState(item))
        .toList();

    _matchscoutingProcess = config.matchscouting.processes
        .map((item) => ProcessConfigEditState(item))
        .toList();

    _fieldStyle = config.fieldStyle;
    fieldImage = config.fieldImage;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                final newConfig = EventConfig(
                  name: _name.text,
                  team: int.parse(_team.text),
                  fieldStyle: _fieldStyle,
                  pit: _pit.map((e) => e.toConfig()).toList(),
                  pitscouting: _pitscouting.map((e) => e.toConfig()).toList(),
                  matchscouting: MatchScouting(
                    events: _matchscoutingEvents
                        .map((e) => e.toConfig())
                        .toList(),
                    processes: _matchscoutingProcess
                        .map((e) => e.toConfig())
                        .toList(),
                    properties: _matchscoutingProperties
                        .map((e) => e.toConfig())
                        .toList(),
                    survey: _matchscoutingSurvey
                        .map((e) => e.toConfig())
                        .toList(),
                  ),
                  tbaEventId: _tbaEventId.text == '' ? null : _tbaEventId.text,
                  tbaSecretKey: _tbaSecretKey.text == ''
                      ? null
                      : _tbaSecretKey.text,
                  fieldImage: fieldImage,
                );
                Navigator.pop(context, newConfig);
              }
            },
            icon: Icon(Icons.save),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          cacheExtent: 9999,
          children: [
            ListTile(
              title: TextFormField(
                controller: _name,
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
                initialValue: _fieldStyle,
                items: [
                  for (final value in FieldStyle.values)
                    DropdownMenuItem<FieldStyle>(
                      value: value,
                      child: Text(value.toString()),
                    ),
                ],
                onChanged: (newValue) => setState(() {
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

            ListTile(title: Text('pit')),
            _buildSurveySection(_pit),

            ListTile(title: Text('pitscouting')),
            _buildSurveySection(_pitscouting),

            ListTile(title: Text('matchscouting')),

            ListTile(title: Text('matchscouting.events')),
            Column(
              children: [
                for (final (idx, item) in _matchscoutingEvents.indexed)
                  Container(
                    color: idx % 2 == 0 ? null : Colors.white12,
                    child: Padding(
                      key: Key(idx.toString()),
                      padding: EdgeInsetsGeometry.only(bottom: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: ListTile(
                              title: EditMatchEventConfig(state: item),
                              leading: IconButton(
                                onPressed: () => setState(() {
                                  _matchscoutingEvents.removeAt(idx);
                                }),
                                icon: Icon(
                                  Icons.remove,
                                  color: Colors.redAccent,
                                ),
                              ),
                            ),
                          ),
                          Column(
                            children: [
                              if (idx > 0)
                                IconButton(
                                  onPressed: () => setState(() {
                                    _matchscoutingEvents.move(idx, idx - 1);
                                  }),
                                  icon: Icon(Icons.arrow_upward),
                                ),
                              if (idx < _matchscoutingEvents.length - 1)
                                IconButton(
                                  onPressed: () => setState(() {
                                    _matchscoutingEvents.move(idx, idx + 1);
                                  }),
                                  icon: Icon(Icons.arrow_downward),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                Center(
                  child: FilledButton.tonalIcon(
                    onPressed: () => setState(() {
                      _matchscoutingEvents.add(
                        MatchEventConfigEditState(
                          MatchEventConfig(id: '', label: ''),
                        ),
                      );
                    }),
                    label: Text('Add'),
                    icon: Icon(Icons.add),
                  ),
                ),
              ],
            ),

            ListTile(title: Text('matchscouting.processes')),
            Column(
              children: [
                for (final (idx, item) in _matchscoutingProcess.indexed)
                  Container(
                    color: idx % 2 == 0 ? null : Colors.white12,
                    child: Padding(
                      key: Key(idx.toString()),
                      padding: EdgeInsetsGeometry.only(bottom: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: ListTile(
                              title: EditProcessConfig(state: item),
                              leading: IconButton(
                                onPressed: () => setState(() {
                                  _matchscoutingProcess.removeAt(idx);
                                }),
                                icon: Icon(
                                  Icons.remove,
                                  color: Colors.redAccent,
                                ),
                              ),
                            ),
                          ),
                          Column(
                            children: [
                              if (idx > 0)
                                IconButton(
                                  onPressed: () => setState(() {
                                    _matchscoutingProcess.move(idx, idx - 1);
                                  }),
                                  icon: Icon(Icons.arrow_upward),
                                ),
                              if (idx < _matchscoutingProcess.length - 1)
                                IconButton(
                                  onPressed: () => setState(() {
                                    _matchscoutingProcess.move(idx, idx + 1);
                                  }),
                                  icon: Icon(Icons.arrow_downward),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                Center(
                  child: FilledButton.tonalIcon(
                    onPressed: () => setState(() {
                      _matchscoutingProcess.add(
                        ProcessConfigEditState(
                          MatchResultsProcess(
                            id: '',
                            label: '',
                            expression: '',
                          ),
                        ),
                      );
                    }),
                    label: Text('Add'),
                    icon: Icon(Icons.add),
                  ),
                ),
              ],
            ),

            ListTile(title: Text('matchscouting.survey')),
            _buildSurveySection(_matchscoutingSurvey),

            ListTile(title: Text('matchscouting.properties')),
            _buildSurveySection(_matchscoutingProperties),

            ListTile(title: Text('fieldImage')),
            ImageViewer(
              child: Image(
                image: memoryImageProvider(base64Decode(fieldImage)),
                fit: BoxFit.cover,
              ),
            ),

            ListTile(
              title: const Text(
                "Set Field Image (2:1 ratio, blue alliance left, scoring table bottom)",
              ),
              leading: const Icon(Icons.map),
              onTap: () async {
                String result;
                try {
                  final bytes = await pickOrTakeImageDialog(context);
                  if (bytes != null) {
                    result = base64Encode(bytes);
                    setState(() {
                      fieldImage = result;
                    });
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

  Widget _buildSurveySection(List<SurveyItemEditState> state) {
    return Column(
      children: [
        for (final (idx, item) in state.indexed)
          Container(
            color: idx % 2 == 0 ? null : Colors.white12,
            child: Padding(
              key: Key(idx.toString()),
              padding: EdgeInsetsGeometry.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    child: ListTile(
                      title: EditSurveyItemConfig(state: item),
                      leading: IconButton(
                        onPressed: () => setState(() {
                          state.removeAt(idx);
                        }),
                        icon: Icon(Icons.remove, color: Colors.redAccent),
                      ),
                    ),
                  ),
                  Column(
                    children: [
                      if (idx > 0)
                        IconButton(
                          onPressed: () => setState(() {
                            state.move(idx, idx - 1);
                          }),
                          icon: Icon(Icons.arrow_upward),
                        ),
                      if (idx < state.length - 1)
                        IconButton(
                          onPressed: () => setState(() {
                            state.move(idx, idx + 1);
                          }),
                          icon: Icon(Icons.arrow_downward),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),

        Center(
          child: FilledButton.tonalIcon(
            onPressed: () => setState(() {
              state.add(
                SurveyItemEditState(
                  DataItemSchema(id: '', type: DataItemType.toggle, label: ''),
                ),
              );
            }),
            label: Text('Add'),
            icon: Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}

// https://stackoverflow.com/questions/66269913/move-elements-in-a-list
extension MoveElement<T> on List<T> {
  void move(int from, int to) {
    RangeError.checkValidIndex(from, this, "from", length);
    RangeError.checkValidIndex(to, this, "to", length);
    var element = this[from];
    if (from < to) {
      setRange(from, to, this, from + 1);
    } else {
      setRange(to + 1, from + 1, this, to);
    }
    this[to] = element;
  }
}
