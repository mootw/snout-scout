//Data class that handles scouting tool things

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:snout_db/event/pitscoutresult.dart';
import 'package:snout_db/config/surveyitem.dart';

double scoutImageSize = 420;

class ScoutingToolWidget extends StatefulWidget {
  final SurveyItem tool;
  final PitScoutResult survey;

  const ScoutingToolWidget(
      {super.key, required this.tool, required this.survey});

  @override
  State<ScoutingToolWidget> createState() => _ScoutingToolWidgetState();
}

class _ScoutingToolWidgetState extends State<ScoutingToolWidget> {
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
        maxLines: 4,
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
        keyboardType: TextInputType.number,
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
          segments: const <ButtonSegment<bool?>>[
            ButtonSegment<bool?>(
                value: false,
                label: Text('false'),
                icon: Icon(Icons.cancel, color: Colors.redAccent)),
            ButtonSegment<bool?>(
                value: null,
                label: Text('null'),
                // icon: Icon(Icons.calendar_view_week)
            ),
            ButtonSegment<bool?>(
                value: true,
                label: Text('true'),
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

      return ListTile(
        title: Text(widget.tool.label),
        trailing: Switch(
            value: _value,
            onChanged: (newValue) {
              setState(() {
                _value = newValue;
              });
            }),
      );
    }

    if (widget.tool.type == SurveyItemType.picture) {
      return ListTile(
        leading: IconButton(
            icon: const Icon(Icons.camera_alt),
            onPressed: () async {
              //TAKE PHOTO
              final ImagePicker picker = ImagePicker();
              final XFile? photo = await picker.pickImage(
                  source: ImageSource.camera,
                  maxWidth: scoutImageSize,
                  maxHeight: scoutImageSize,
                  imageQuality: 50);
              if (photo != null) {
                Uint8List bytes = await photo.readAsBytes();
                setState(() {
                  _value = base64Encode(bytes);
                });
              }
            }),
        title: Text(widget.tool.label),
        subtitle: _value == null
            ? const Text("No Image")
            : SizedBox(
                height: scoutImageSize,
                child: Image.memory(
                    Uint8List.fromList(base64Decode(_value).cast<int>()))),
      );
    }

    return Text("Unknown tool ${widget.tool.id}");
  }
}
