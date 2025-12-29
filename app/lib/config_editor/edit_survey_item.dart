import 'package:app/screens/view_team_page.dart';
import 'package:flutter/material.dart';
import 'package:snout_db/config/data_item_schema.dart';

class SurveyItemEditState {
  late TextEditingController label;
  late TextEditingController id;
  late DataItemType type;
  late TextEditingController docs;
  late List<TextEditingController>? options;
  late bool isSensitiveField;

  SurveyItemEditState(DataItemSchema config) {
    label = TextEditingController(text: config.label);
    id = TextEditingController(text: config.id);
    type = config.type;
    docs = TextEditingController(text: config.docs);
    options = config.options
        ?.map((item) => TextEditingController(text: item))
        .toList();
    isSensitiveField = config.isSensitiveField;
  }

  DataItemSchema toConfig() {
    return DataItemSchema(
      id: id.text,
      type: type,
      label: label.text,
      docs: docs.text,
      options: options?.map((controller) => controller.text).toList() ?? [],
      isSensitiveField: isSensitiveField,
    );
  }
}

final specialValues = [
  robotPictureReserved,
  teamNameReserved,
  teamNotesReserved,
  'needs_help',
];

final invalidIdValues = RegExp(r'[^A-Za-z0-9_]');

class EditSurveyItemConfig extends StatefulWidget {
  final SurveyItemEditState state;

  const EditSurveyItemConfig({super.key, required this.state});

  @override
  State<EditSurveyItemConfig> createState() => _EditSurveyItemConfigState();
}

class _EditSurveyItemConfigState extends State<EditSurveyItemConfig> {
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
          title: RawAutocomplete(
            textEditingController: widget.state.id,
            focusNode: FocusNode(),
            optionsBuilder: (textEditingValue) {
              return specialValues.where(
                (value) => value.contains(textEditingValue.text.toLowerCase()),
              );
            },
            fieldViewBuilder: (context, controller, focusNode, onSubmit) {
              return TextFormField(
                controller: controller,
                focusNode: focusNode,
                decoration: InputDecoration(
                  label: Text('id'),
                  border: const OutlineInputBorder(),
                ),
              );
            },
            optionsViewBuilder:
                (
                  BuildContext context,
                  void Function(String) onSelected,
                  Iterable<String> options,
                ) {
                  return Column(
                    children: [
                      for (final option in options)
                        Container(
                          color: Theme.of(context).canvasColor,
                          child: ListTile(
                            title: Text(option),
                            onTap: () => onSelected(option),
                          ),
                        ),
                    ],
                  );
                },
          ),
        ),
        ListTile(
          title: DropdownButtonFormField(
            initialValue: widget.state.type,
            items: [
              for (final value in DataItemType.values)
                DropdownMenuItem<DataItemType>(
                  value: value,
                  child: Text(value.toString()),
                ),
            ],
            onChanged: (newValue) => setState(() {
              widget.state.type = newValue!;
            }),
            decoration: InputDecoration(
              label: Text('type'),
              border: const OutlineInputBorder(),
            ),
          ),
        ),

        if (widget.state.type == DataItemType.selector) ...[
          ListTile(title: Text('options')),
          ListView(
            shrinkWrap: true,
            children: [
              for (final (idx, item)
                  in (widget.state.options ?? <TextEditingController>[])
                      .indexed)
                ListTile(
                  title: TextFormField(
                    controller: item,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  leading: IconButton(
                    onPressed: () => setState(() {
                      widget.state.options?.removeAt(idx);
                      if (widget.state.options?.isEmpty == true) {
                        widget.state.options = null;
                      }
                    }),
                    icon: Icon(Icons.remove, color: Colors.redAccent),
                  ),
                ),
            ],
          ),
          Center(
            child: FilledButton.tonalIcon(
              onPressed: () => setState(() {
                if (widget.state.options == null) {
                  widget.state.options = <TextEditingController>[];
                }
                widget.state.options?.add(TextEditingController());
              }),
              label: Text('Add'),
              icon: Icon(Icons.add),
            ),
          ),
        ],
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
          title: Text('isSensitiveField'),
          trailing: Switch(
            value: widget.state.isSensitiveField,
            onChanged: (newValue) => setState(() {
              widget.state.isSensitiveField = newValue;
            }),
          ),
        ),
      ],
    );
  }
}
