import 'package:app/config_editor/edit_survey_item.dart';
import 'package:flutter/material.dart';
import 'package:snout_db/config/match_period_config.dart';

class MatchPeriodEditState {
  late TextEditingController label;
  late TextEditingController id;
  late TextEditingController durationInSeconds;

  MatchPeriodEditState(MatchPeriodConfig config) {
    label = TextEditingController(text: config.label);
    id = TextEditingController(text: config.id);
    durationInSeconds = TextEditingController(
      text: config.durationSeconds.toString(),
    );
  }

  MatchPeriodConfig toConfig() {
    return MatchPeriodConfig(
      id: id.text,
      label: label.text,
      durationSeconds: int.parse(durationInSeconds.text),
    );
  }
}

class EditMatchPeriod extends StatefulWidget {
  final MatchPeriodEditState state;

  const EditMatchPeriod({super.key, required this.state});

  @override
  State<EditMatchPeriod> createState() => _EditMatchPeriodState();
}

class _EditMatchPeriodState extends State<EditMatchPeriod> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          title: TextFormField(
            controller: widget.state.label,
            onEditingComplete: () {
              if (widget.state.id.text == '') {
                widget.state.id.text = widget.state.label.text
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
            controller: widget.state.durationInSeconds,
            decoration: InputDecoration(
              label: Text('durationInSeconds'),
              border: const OutlineInputBorder(),
            ),
            validator: (value) => value != null && int.tryParse(value) == null
                ? 'Must be an integer'
                : (int.parse(value!) > 0 ? null : 'Must be greater than zero'),
          ),
        ),
      ],
    );
  }
}
