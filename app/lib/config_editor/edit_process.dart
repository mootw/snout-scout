import 'package:flutter/material.dart';
import 'package:snout_db/config/matchresults_process.dart';

class ProcessConfigEditState {
  late TextEditingController label;
  late TextEditingController id;
  late bool isLargerBetter;
  late TextEditingController expression;
  late TextEditingController docs;

  ProcessConfigEditState(MatchResultsProcess config) {
    label = TextEditingController(text: config.label);
    id = TextEditingController(text: config.id);
    expression = TextEditingController(text: config.expression);
    isLargerBetter = config.isLargerBetter;
    docs = TextEditingController(text: config.docs);
  }

  MatchResultsProcess toConfig() {
    return MatchResultsProcess(
      id: id.text,
      label: label.text,
      expression: expression.text,
      docs: docs.text,
      isLargerBetter: isLargerBetter,
    );
  }
}

class EditProcessConfig extends StatefulWidget {
  final ProcessConfigEditState state;

  const EditProcessConfig({super.key, required this.state});

  @override
  State<EditProcessConfig> createState() => _EditProcessConfigState();
}

class _EditProcessConfigState extends State<EditProcessConfig> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          title: TextFormField(
            controller: widget.state.label,
            onChanged: (newValue) {},
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
            controller: widget.state.expression,
            maxLines: 10,
            minLines: 1,
            decoration: InputDecoration(
              label: Text('expression'),
              border: const OutlineInputBorder(),
            ),
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
