import 'package:app/config_editor/edit_survey_item.dart';
import 'package:app/style.dart';
import 'package:flutter/material.dart';
import 'package:snout_db/config/matcheventconfig.dart';

class MatchEventConfigEditState {
  late TextEditingController label;
  late TextEditingController id;
  late bool isLargerBetter;
  late TextEditingController color;
  late TextEditingController docs;

  MatchEventConfigEditState(MatchEventConfig config) {
    label = TextEditingController(text: config.label);
    id = TextEditingController(text: config.id);
    color = TextEditingController(text: config.color);
    isLargerBetter = config.isLargerBetter;
    docs = TextEditingController(text: config.docs);
  }

  MatchEventConfig toConfig() {
    return MatchEventConfig(
      id: id.text,
      label: label.text,
      color: color.text,
      docs: docs.text,
      isLargerBetter: isLargerBetter,
    );
  }
}

class EditMatchEventConfig extends StatefulWidget {
  final MatchEventConfigEditState state;

  const EditMatchEventConfig({super.key, required this.state});

  @override
  State<EditMatchEventConfig> createState() => _EditMatchEventConfigState();
}

class _EditMatchEventConfigState extends State<EditMatchEventConfig> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          title: TextFormField(
            controller: widget.state.label,
            onEditingComplete: () {
              if (widget.state.id.text == '') {
                widget.state.id.text =
                    widget.state.label.text
                        .toLowerCase()
                        .replaceAll(' ', '_')
                        .replaceAll(invalidIdValues, '')
                        .trim();
              }
            },
            decoration: InputDecoration(
              label: Text('label'),
              border: const OutlineInputBorder(),
            ),
          ),
        ),
        ListTile(
          title: TextFormField(
            controller: widget.state.id,
            decoration: InputDecoration(
              label: Text('id'),
              border: const OutlineInputBorder(),
            ),
          ),
        ),
        ListTile(
          title: TextFormField(
            controller: widget.state.color,
            onChanged:
                (newValue) => setState(() {
                  // TODO handle this more elegantly
                  //Update the color swatch
                }),
            decoration: InputDecoration(
              label: Text('color'),
              border: const OutlineInputBorder(),
            ),
          ),
          trailing: Icon(
            Icons.circle,
            color: colorFromHex(widget.state.color.text),
          ),
        ),

        ListTile(
          title: TextFormField(
            controller: widget.state.docs,
            maxLines: 4,
            minLines: 1,
            decoration: InputDecoration(
              label: Text('docs'),
              border: const OutlineInputBorder(),
            ),
          ),
        ),
        ListTile(
          title: Text('isLargerBetter'),
          trailing: Switch(
            value: widget.state.isLargerBetter,
            onChanged:
                (newValue) => setState(() {
                  widget.state.isLargerBetter = newValue;
                }),
          ),
        ),
      ],
    );
  }
}
