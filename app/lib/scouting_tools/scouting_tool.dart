//Data class that handles scouting tool things

import 'package:app/data/scouting_config.dart';
import 'package:app/data/scouting_result.dart';
import 'package:flutter/material.dart';

class ScoutingToolWidget extends StatefulWidget {
  final ScoutingToolData tool;
  final Survey survey;

  const ScoutingToolWidget({Key? key, required this.tool, required this.survey})
      : super(key: key);

  @override
  State<ScoutingToolWidget> createState() => _ScoutingToolWidgetState();
}

class _ScoutingToolWidgetState extends State<ScoutingToolWidget> {
  final myController = TextEditingController();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    if (widget.tool.type == "toggle" && widget.survey.value == null) {
      widget.survey.value = false;
    }

    if (widget.tool.type == "text-box" || widget.tool.type == "number") {
      myController.text = widget.survey.value?.toString() ?? "";
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.tool.type == "text-box") {
      return TextField(
        controller: myController,
        onChanged: (text) {
          widget.survey.value = text;
        },
        minLines: 1,
        maxLines: 4,
        decoration: InputDecoration(
          label: Text(widget.tool.label),
          border: OutlineInputBorder(),
        ),
      );
    }

    if (widget.tool.type == "number") {
      return TextField(
        controller: myController,
        onChanged: (text) {
          widget.survey.value = num.tryParse(text);
        },
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          label: Text(widget.tool.label),
          border: OutlineInputBorder(),
        ),
      );
    }

    if (widget.tool.type == "selector") {
      return ListTile(
        title: Text(widget.tool.label),
        trailing: DropdownButton<String>(
          value: widget.survey.value,
          icon: const Icon(Icons.arrow_downward),
          onChanged: (String? newValue) {
            setState(() {
              widget.survey.value = newValue!;
            });
          },
          items:
              widget.tool.options.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
        ),
      );
    }

    if (widget.tool.type == "toggle") {
      return ListTile(
        title: Text(widget.tool.label),
        trailing: Switch(
            value: widget.survey.value,
            onChanged: (value) {
              setState(() {
                widget.survey.value = value;
              });
            }),
      );
    }

    return Text("Unknown tool ${widget.tool.id}");
  }
}
