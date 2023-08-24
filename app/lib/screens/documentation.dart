import 'package:app/providers/data_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';

class DocumentationScreen extends StatefulWidget {
  const DocumentationScreen({super.key});

  @override
  State<DocumentationScreen> createState() => _DocumentationScreenState();
}

class _DocumentationScreenState extends State<DocumentationScreen> {
  
  bool _showDetails = false;

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>().db.config;

    return ListView(
      children: [
        ListTile(
          title: const Text("Show Technical Details"),
          trailing: Switch(
            value: _showDetails,
            onChanged: (value) => setState(() {
              _showDetails = value;
            }),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Text("Pit Scouting",
              style: Theme.of(context).textTheme.titleLarge),
        ),
        for (final item in data.pitscouting) ...[
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 16),
            child: Text(item.label,
                style: Theme.of(context).textTheme.titleMedium),
          ),
          if(_showDetails)
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Text("id: ${item.id}", style: Theme.of(context).textTheme.bodySmall),
          ),
          if(_showDetails)
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Text("options: ${item.options}", style: Theme.of(context).textTheme.bodySmall),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 4),
            child: item.docs == null
                ? const Text("No Docs")
                : Markdown(data: item.docs!),
          )
        ],
        const Divider(),
        Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Text("Match Events",
              style: Theme.of(context).textTheme.titleLarge),
        ),
        for (final item in data.matchscouting.events) ...[
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 16),
            child: Text(item.label,
                style: Theme.of(context).textTheme.titleMedium),
          ),
          if(_showDetails)
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Text("id: ${item.id}", style: Theme.of(context).textTheme.bodySmall),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 4),
            child: item.docs == null
                ? const Text("No Docs")
                : Markdown(data: item.docs!),
          )
        ],
        const Divider(),
        Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Text("Match Survey",
              style: Theme.of(context).textTheme.titleLarge),
        ),
        for (final item in data.matchscouting.survey) ...[
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 16),
            child: Text(item.label,
                style: Theme.of(context).textTheme.titleMedium),
          ),
          if(_showDetails)
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Text("id: ${item.id}", style: Theme.of(context).textTheme.bodySmall),
          ),
          if(_showDetails)
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Text("options: ${item.options}", style: Theme.of(context).textTheme.bodySmall),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 4),
            child: item.docs == null
                ? const Text("No Docs")
                : Markdown(data: item.docs!),
          )
        ],
        const Divider(),
        Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Text("Processes",
              style: Theme.of(context).textTheme.titleLarge),
        ),
        for (final item in data.matchscouting.processes) ...[
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 16),
            child: Text(item.label,
                style: Theme.of(context).textTheme.titleMedium),
          ),
          if(_showDetails)
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Text("id: ${item.id}", style: Theme.of(context).textTheme.bodySmall),
          ),
          if(_showDetails)
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Text("expression: ${item.expression}", style: Theme.of(context).textTheme.bodySmall),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 4),
            child: item.docs == null
                ? const Text("No Docs")
                : Markdown(data: item.docs!),
          )
        ],
      ],
    );
  }
}
