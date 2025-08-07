import 'package:flutter/material.dart';
import 'package:snout_db/config/surveyitem.dart';

class EditSurveyItemConfig extends StatelessWidget {
  final SurveyItem config;

  const EditSurveyItemConfig({super.key, required this.config});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          title: TextFormField(
            initialValue: config.label,
            decoration: InputDecoration(
              label: Text('label'),
              border: const OutlineInputBorder(),
            ),
          ),
        ),
        ListTile(
          title: TextFormField(
            initialValue: config.id,
            decoration: InputDecoration(
              label: Text('id'),
              border: const OutlineInputBorder(),
            ),
          ),
        ),
        ListTile(
          title: DropdownButtonFormField(
            value: config.type,
            items: [
              for (final value in SurveyItemType.values)
                DropdownMenuItem<SurveyItemType>(
                  value: value,
                  child: Text(value.toString()),
                ),
            ],
            onChanged: (newValue) => () {},
            decoration: InputDecoration(
              label: Text('fieldStyle'),
              border: const OutlineInputBorder(),
            ),
          ),
        ),

        if (config.type == SurveyItemType.selector) ...[
          ListTile(title: Text('options')),
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Column(
              children: [
                for (final item in config.options ?? <String>[])
                  ListTile(
                    title: TextFormField(
                      initialValue: item,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    trailing: IconButton(
                      onPressed: () {}, //TODO implement
                      icon: Icon(Icons.remove, color: Colors.redAccent,),
                    ),
                  ),
                Center(
                  child: FilledButton.tonalIcon(
                    onPressed: () => (), //TODO implement
                    label: Text('Add'),
                    icon: Icon(Icons.add),
                  ),
                ),
              ],
            ),
          ),
        ],
         ListTile(
          title: TextFormField(
            initialValue: config.docs,
            maxLines: 4,
            minLines: 1,
            decoration: InputDecoration(
              label: Text('docs'),
              border: const OutlineInputBorder(),
            ),
          ),
        ),
      ],
    );
  }
}
