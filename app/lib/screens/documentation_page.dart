import 'dart:convert';
import 'dart:typed_data';

import 'package:app/providers/cache_memory_imageprovider.dart';
import 'package:app/style.dart';
import 'package:app/providers/data_provider.dart';
import 'package:app/providers/identity_provider.dart';
import 'package:app/screens/debug_field_position.dart';
import 'package:app/widgets/image_view.dart';
import 'package:app/widgets/markdown_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import 'package:snout_db/patch.dart';
import 'package:url_launcher/url_launcher_string.dart';

class DocumentationScreen extends StatefulWidget {
  const DocumentationScreen({super.key});

  @override
  State<DocumentationScreen> createState() => _DocumentationScreenState();
}

class _DocumentationScreenState extends State<DocumentationScreen> {
  bool _showDetails = false;

  @override
  Widget build(BuildContext context) {
    final config = context.watch<DataProvider>().event.config;

    final pitMap = context.watch<DataProvider>().event.pitmap;

    return ListView(
      //helps keep the scrollbar consistent at the cost of performance
      cacheExtent: 5000,
      children: [
        ListTile(
          title: const Text("Snout Scout docs"),
          leading: const Icon(Icons.menu_book),
          onTap: () => launchUrlString(
              "https://github.com/mootw/snout-scout/blob/main/readme.md"),
        ),
        ListTile(
          title: const Text("DEBUG Field position"),
          leading: const Icon(Icons.crop_square_sharp),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const DebugFieldPosition()),
            );
          },
        ),
        const Divider(),
        if (pitMap != null)
          SizedBox(
              height: 250,
              child: ImageViewer(
                child: Image(
                  image: CacheMemoryImageProvider(pitMap),
                  fit: BoxFit.fitHeight,
                  width: 2000,
                ),
              )),
        if (pitMap == null)
          const ListTile(title: Text("No pit map has been added yet :(")),
        ListTile(
          title: const Text("Set Pit Map Image"),
          leading: const Icon(Icons.camera_alt),
          onTap: () async {
            final identity = context.read<IdentityProvider>().identity;
            final dataProvider = context.read<DataProvider>();

            String result;
            try {
              // FOR THE PIT MAP ALLOW FOR resolution higher than the standard scouting
              // image. This is because the pitmap might contain super small text
              final photo =
                  await pickOrTakeImageDialog(context, scoutImageSize * 1.5);
              if (photo != null) {
                Uint8List bytes = await photo.readAsBytes();
                result = base64Encode(bytes);
                Patch patch = Patch(
                    identity: identity,
                    time: DateTime.now(),
                    path: Patch.buildPath(['pitmap']),
                    value: result);
                //Save the scouting results to the server!!
                await dataProvider.newTransaction(patch);
              }
            } catch (e, s) {
              Logger.root.severe("Error taking image from device", e, s);
            }
          },
        ),
        const Divider(),
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 16),
          child: MarkdownText(
              data: config.docs.isNotEmpty
                  ? config.docs
                  : "# Welcome to the docs for ${config.name}\n**this is a temporary message that will be replaced once you set the docs property in the event config**\n\neverything that you collect should be defined in here, all 'docs' properties in the configuration support markdown"),
        ),
        const Divider(),
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
        for (final item in config.pitscouting) ...[
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 16),
            child: Text(item.label,
                style: Theme.of(context).textTheme.titleMedium),
          ),
          if (_showDetails)
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Text("id: ${item.id}",
                  style: Theme.of(context).textTheme.bodySmall),
            ),
          if (_showDetails)
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Text("type: ${item.type}",
                  style: Theme.of(context).textTheme.bodySmall),
            ),
          if (_showDetails)
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Text("options: ${item.options}",
                  style: Theme.of(context).textTheme.bodySmall),
            ),
          Padding(
            padding: const EdgeInsets.only(left: 32, top: 4, right: 16),
            child: MarkdownText(data: item.docs),
          )
        ],
        const Divider(),
        Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Text("Match Events",
              style: Theme.of(context).textTheme.titleLarge),
        ),
        for (final item in config.matchscouting.events) ...[
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 16),
            child: Text(item.label,
                style: Theme.of(context).textTheme.titleMedium),
          ),
          if (_showDetails)
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Text("color: ${item.color}",
                  style: Theme.of(context).textTheme.bodySmall),
            ),
          if (_showDetails)
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Text("id: ${item.id}",
                  style: Theme.of(context).textTheme.bodySmall),
            ),
          Padding(
            padding: const EdgeInsets.only(left: 32, top: 4, right: 16),
            child: MarkdownText(data: item.docs),
          )
        ],
        const Divider(),
        Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Text("Match Survey",
              style: Theme.of(context).textTheme.titleLarge),
        ),
        for (final item in config.matchscouting.survey) ...[
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 16),
            child: Text(item.label,
                style: Theme.of(context).textTheme.titleMedium),
          ),
          if (_showDetails)
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Text("id: ${item.id}",
                  style: Theme.of(context).textTheme.bodySmall),
            ),
          if (_showDetails)
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Text("type: ${item.type}",
                  style: Theme.of(context).textTheme.bodySmall),
            ),
          if (_showDetails)
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Text("options: ${item.options}",
                  style: Theme.of(context).textTheme.bodySmall),
            ),
          Padding(
            padding: const EdgeInsets.only(left: 32, top: 4, right: 16),
            child: MarkdownText(data: item.docs),
          )
        ],
        const Divider(),
        Padding(
          padding: const EdgeInsets.only(left: 16),
          child:
              Text("Processes", style: Theme.of(context).textTheme.titleLarge),
        ),
        for (final item in config.matchscouting.processes) ...[
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 16),
            child: Text(item.label,
                style: Theme.of(context).textTheme.titleMedium),
          ),
          if (_showDetails)
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Text("id: ${item.id}",
                  style: Theme.of(context).textTheme.bodySmall),
            ),
          if (_showDetails)
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Text("expression: ${item.expression}",
                  style: Theme.of(context).textTheme.bodySmall),
            ),
          Padding(
            padding: const EdgeInsets.only(left: 32, top: 4, right: 16),
            child: MarkdownText(data: item.docs),
          )
        ],
      ],
    );
  }
}
