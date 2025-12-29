//Data class that handles scouting tool things

import 'package:app/screens/edit_markdown.dart';
import 'package:app/services/snout_image_cache.dart';
import 'package:app/style.dart';
import 'package:app/widgets/markdown_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:snout_db/config/data_item_schema.dart';
import 'package:snout_db/event/dynamic_property.dart';

class DynamicPropertyEditorWidget extends StatefulWidget {
  final DataItemSchema tool;
  final DynamicProperties survey;
  final DynamicProperties? initialData;

  const DynamicPropertyEditorWidget({
    super.key,
    required this.tool,
    required this.survey,
    this.initialData,
  });

  @override
  State<DynamicPropertyEditorWidget> createState() =>
      _DynamicPropertyEditorWidgetState();
}

class _DynamicPropertyEditorWidgetState
    extends State<DynamicPropertyEditorWidget> {
  final _myController = TextEditingController();

  get _initialValue => widget.initialData?[widget.tool.id];

  get _value => widget.survey[widget.tool.id];
  set _value(dynamic newValue) => widget.survey[widget.tool.id] = newValue;

  @override
  void initState() {
    super.initState();
    if (widget.tool.type == DataItemType.text ||
        widget.tool.type == DataItemType.number) {
      _myController.text = _value?.toString() ?? "";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (_value != _initialValue)
          IconButton(
            onPressed: () => setState(() {
              _value = _initialValue;
              if (widget.tool.type == DataItemType.text ||
                  widget.tool.type == DataItemType.number) {
                _myController.text =
                    _initialValue ?? ""; // _initialValue can be null!
              }
            }),
            icon: const Icon(Icons.restore),
          ),
        Expanded(
          child: switch (widget.tool.type) {
            DataItemType.text => Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _myController,
                    onChanged: (text) {
                      setState(() {
                        _value = text;
                        //TO prevent previously filled but now unfilled data from showing as empty.
                        if (text == "") {
                          _value = null;
                        }
                      });
                    },
                    minLines: 1,
                    maxLines: 8,
                    decoration: InputDecoration(
                      label: Text(widget.tool.label),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                // Allow editing the text field in a fullscreen markdown editor
                IconButton(
                  icon: Icon(Icons.edit_note),
                  onPressed: () async {
                    final text = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            EditMarkdownPage(source: _myController.text),
                      ),
                    );
                    if (text != null) {
                      setState(() {
                        _value = text;
                        _myController.text = text;
                        //TO prevent previously filled but now unfilled data from showing as empty.
                        if (text == "") {
                          _value = null;
                        }
                      });
                    }
                  },
                ),
              ],
            ),
            DataItemType.number => TextFormField(
              //Numbers or no value only
              validator: (value) {
                if (value == null || value == "") {
                  //No value is fine
                  return null;
                }
                //Check if number
                return num.tryParse(value) != null
                    ? null
                    : "Value must be a number";
              },
              controller: _myController,
              onChanged: (text) {
                setState(() {
                  if (text == "") {
                    //Empty input should be null
                    _value = null;
                  }
                  _value = num.tryParse(text);
                });
              },
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              decoration: InputDecoration(
                label: Text(widget.tool.label),
                border: const OutlineInputBorder(),
              ),
            ),
            DataItemType.selector => ListTile(
              title: Text(widget.tool.label),
              subtitle: DropdownButton<String>(
                value: _value,
                icon: const Icon(Icons.arrow_downward),
                onChanged: (String? newValue) {
                  setState(() {
                    _value = newValue;
                  });
                },
                //Insert empty value here as an option
                items: [null, ...widget.tool.options!]
                    .map<DropdownMenuItem<String>>((String? value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value ?? ""),
                      );
                    })
                    .toList(),
              ),
            ),
            DataItemType.toggle => ListTile(
              title: Text(widget.tool.label),
              subtitle: SegmentedButton<bool?>(
                showSelectedIcon: false,
                segments: const <ButtonSegment<bool?>>[
                  ButtonSegment<bool?>(
                    value: false,
                    // label: Text('false'),
                    icon: Icon(Icons.cancel, color: Colors.redAccent),
                  ),
                  ButtonSegment<bool?>(
                    value: null,
                    // label: Text('unknown'),
                    icon: Icon(Icons.question_mark),
                  ),
                  ButtonSegment<bool?>(
                    value: true,
                    // label: Text('true'),
                    icon: Icon(Icons.check_circle, color: Colors.greenAccent),
                  ),
                ],
                selected: {_value},
                onSelectionChanged: (Set<bool?> newValue) {
                  setState(() {
                    _value = newValue.first;
                  });
                },
              ),
            ),
            DataItemType.picture => ListTile(
              leading: IconButton(
                icon: const Icon(Icons.camera_alt),
                onPressed: () async {
                  try {
                    final bytes = await pickOrTakeImageDialog(context);
                    if (bytes != null) {
                      setState(() {
                        _value = bytes;
                      });
                    }
                  } catch (e, s) {
                    Logger.root.severe("Error taking image from device", e, s);
                  }
                },
              ),
              title: Text(widget.tool.label),
              subtitle: _value == null
                  ? const Text("No Image")
                  : Image(
                      image: snoutImageCache.getCached(_value),
                      fit: BoxFit.contain,
                    ),
            ),
          },
        ),
        Padding(
          padding: const EdgeInsets.only(left: 8),
          child: SurveyItemDocs(tool: widget.tool),
        ),
      ],
    );
  }
}

class SurveyItemDocs extends StatelessWidget {
  final DataItemSchema tool;

  const SurveyItemDocs({required this.tool, super.key});

  @override
  Widget build(BuildContext context) {
    if (tool.docs.isEmpty) {
      // Do not display the indicator if the docs are an empty string
      return const SizedBox();
    }
    return IconButton.filledTonal(
      iconSize: 16,
      visualDensity: VisualDensity.compact,
      onPressed: () => showDialog(
        context: context,
        builder: (context) => AlertDialog(
          content: MarkdownText(data: tool.docs),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Ok'),
            ),
          ],
        ),
      ),
      icon: const Icon(Icons.question_mark),
    );
  }
}
