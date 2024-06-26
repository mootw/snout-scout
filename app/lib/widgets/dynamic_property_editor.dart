//Data class that handles scouting tool things

import 'dart:convert';
import 'dart:typed_data';

import 'package:app/providers/cache_memory_imageprovider.dart';
import 'package:app/style.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:snout_db/config/surveyitem.dart';
import 'package:snout_db/event/dynamic_property.dart';

class DynamicPropertyEditorWidget extends StatefulWidget {
  final SurveyItem tool;
  final DynamicProperties survey;

  const DynamicPropertyEditorWidget(
      {super.key, required this.tool, required this.survey});

  @override
  State<DynamicPropertyEditorWidget> createState() =>
      _DynamicPropertyEditorWidgetState();
}

class _DynamicPropertyEditorWidgetState
    extends State<DynamicPropertyEditorWidget> {
  final _myController = TextEditingController();

  get _value => widget.survey[widget.tool.id];
  set _value(dynamic newValue) => widget.survey[widget.tool.id] = newValue;

  @override
  void initState() {
    super.initState();
    if (widget.tool.type == SurveyItemType.text ||
        widget.tool.type == SurveyItemType.number) {
      _myController.text = _value?.toString() ?? "";
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.tool.type == SurveyItemType.text) {
      return TextFormField(
        controller: _myController,
        onChanged: (text) {
          _value = text;
          //TO prevent previously filled but now unfilled data from showing as empty.
          if (text == "") {
            _value = null;
          }
        },
        minLines: 1,
        maxLines: 8,
        decoration: InputDecoration(
          label: Text(widget.tool.label),
          border: const OutlineInputBorder(),
        ),
      );
    }

    if (widget.tool.type == SurveyItemType.number) {
      return TextFormField(
        //Numbers or no value only
        validator: (value) {
          if (value == null || value == "") {
            //No value is fine
            return null;
          }
          //Check if number
          return num.tryParse(value) != null ? null : "Value must be a number";
        },
        controller: _myController,
        onChanged: (text) {
          if (text == "") {
            //Empty input should be null
            _value = null;
          }
          _value = num.tryParse(text);
        },
        keyboardType:
            const TextInputType.numberWithOptions(decimal: true, signed: true),
        decoration: InputDecoration(
          label: Text(widget.tool.label),
          border: const OutlineInputBorder(),
        ),
      );
    }

    if (widget.tool.type == SurveyItemType.selector) {
      return ListTile(
        title: Text(widget.tool.label),
        trailing: DropdownButton<String>(
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
          }).toList(),
        ),
      );
    }

    if (widget.tool.type == SurveyItemType.toggle) {
      return ListTile(
        title: Text(widget.tool.label),
        trailing: SegmentedButton<bool?>(
          showSelectedIcon: false,
          segments: const <ButtonSegment<bool?>>[
            ButtonSegment<bool?>(
                value: false,
                // label: Text('false'),
                icon: Icon(Icons.cancel, color: Colors.redAccent)),
            ButtonSegment<bool?>(
              value: null,
              // label: Text('unknown'),
              icon: Icon(Icons.question_mark),
            ),
            ButtonSegment<bool?>(
                value: true,
                // label: Text('true'),
                icon: Icon(Icons.check_circle, color: Colors.greenAccent)),
          ],
          selected: {_value},
          onSelectionChanged: (Set<bool?> newValue) {
            setState(() {
              _value = newValue.first;
            });
          },
        ),
      );
    }

    if (widget.tool.type == SurveyItemType.picture) {
      return ListTile(
        leading: IconButton(
            icon: const Icon(Icons.camera_alt),
            onPressed: () async {
              try {
                final photo = await pickOrTakeImageDialog(context);
                if (photo != null) {
                  Uint8List bytes = await photo.readAsBytes();
                  setState(() {
                    _value = base64Encode(bytes);
                  });
                }
              } catch (e, s) {
                Logger.root.severe("Error taking image from device", e, s);
              }
            }),
        title: Text(widget.tool.label),
        subtitle: _value == null
            ? const Text("No Image")
            : Image(
                image: CacheMemoryImageProvider(
                    Uint8List.fromList(base64Decode(_value).cast<int>())),
                fit: BoxFit.contain,
              ),
      );
    }

    return Text("Unknown tool ${widget.tool.id}");
  }
}
