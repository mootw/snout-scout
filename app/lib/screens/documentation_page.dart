import 'dart:convert';

import 'package:app/data_submit_login.dart';
import 'package:app/providers/data_provider.dart';
import 'package:app/providers/identity_provider.dart';
import 'package:app/screens/debug_field_position.dart';
import 'package:app/services/snout_image_cache.dart';
import 'package:app/style.dart';
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

    final techDetailStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: Theme.of(context).textTheme.bodySmall?.color?.withAlpha(200),
    );

    return Scaffold(
      body: ListView(
        //helps keep the scrollbar consistent at the cost of performance
        cacheExtent: 5000,
        children: [
          ListTile(
            title: const Text("Snout Scout docs"),
            leading: const Icon(Icons.menu_book),
            onTap:
                () => launchUrlString(
                  "https://github.com/mootw/snout-scout/blob/main/readme.md",
                ),
          ),
          ListTile(
            title: const Text("DEBUG Field position"),
            leading: const Icon(Icons.crop_square_sharp),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DebugFieldPosition(),
                ),
              );
            },
          ),
          const Divider(),
          if (pitMap != null)
            SizedBox(
              height: 250,
              child: ImageViewer(
                child: Image(
                  image: snoutImageCache.getCached(pitMap),
                  fit: BoxFit.fitHeight,
                  width: 2000,
                ),
              ),
            ),
          if (pitMap == null)
            const ListTile(title: Text("No pitmap has been set yet :(")),
          ListTile(
            title: const Text("Set Pit Map Image"),
            leading: const Icon(Icons.camera_alt),
            onTap: () async {
              final identity = context.read<IdentityProvider>().identity;

              String result;
              try {
                final bytes = await pickOrTakeImageDialog(
                  context
                );
                if (bytes != null) {
                  result = base64Encode(bytes);
                  Patch patch = Patch(
                    identity: identity,
                    time: DateTime.now(),
                    path: Patch.buildPath(['pitmap']),
                    value: result,
                  );
                  //Save the scouting results to the server!!
                  if (context.mounted) {
                    await submitData(context, patch);
                  }
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
              data:
                  config.docs.isNotEmpty
                      ? config.docs
                      : "# Welcome to the docs for ${config.name}\n**this is a temporary message that will be replaced once you set the docs property in the event config**\n\neverything that you collect should be defined in here, all 'docs' properties in the configuration support markdown",
            ),
          ),
          const Divider(),
          ListTile(
            title: const Text("Show Technical Details"),
            trailing: Switch(
              value: _showDetails,
              onChanged:
                  (value) => setState(() {
                    _showDetails = value;
                  }),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Text(
              "Pit Scouting",
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          for (final item in config.pitscouting) ...[
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 16),
              child: Text(
                item.label,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            if (_showDetails)
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Text("id: ${item.id}", style: techDetailStyle),
              ),
            if (_showDetails)
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Text("type: ${item.type}", style: techDetailStyle),
              ),
            if (_showDetails)
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Text("options: ${item.options}", style: techDetailStyle),
              ),
            Padding(
              padding: const EdgeInsets.only(left: 32, top: 2, right: 16),
              child: MarkdownText(data: item.docs),
            ),
          ],
          const Divider(),
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Text(
              "Match Events",
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          for (final item in config.matchscouting.events) ...[
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 16),
              child: Text(
                item.label,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            if (_showDetails)
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Text("color: ${item.color}", style: techDetailStyle),
              ),
            if (_showDetails)
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Text("id: ${item.id}", style: techDetailStyle),
              ),
            Padding(
              padding: const EdgeInsets.only(left: 32, top: 4, right: 16),
              child: MarkdownText(data: item.docs),
            ),
          ],
          const Divider(),
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Text(
              "Match Survey",
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          for (final item in config.matchscouting.survey) ...[
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 16),
              child: Text(
                item.label,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            if (_showDetails)
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Text("id: ${item.id}", style: techDetailStyle),
              ),
            if (_showDetails)
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Text("type: ${item.type}", style: techDetailStyle),
              ),
            if (_showDetails)
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Text("options: ${item.options}", style: techDetailStyle),
              ),
            Padding(
              padding: const EdgeInsets.only(left: 32, top: 4, right: 16),
              child: MarkdownText(data: item.docs),
            ),
          ],
          const Divider(),
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Text(
              "Processes",
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          for (final item in config.matchscouting.processes) ...[
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 16),
              child: Text(
                item.label,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            if (_showDetails)
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Text("id: ${item.id}", style: techDetailStyle),
              ),
            if (_showDetails)
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Text(
                  "expression: ${item.expression}",
                  style: techDetailStyle,
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(left: 32, top: 4, right: 16),
              child: MarkdownText(data: item.docs),
            ),
          ],
        ],
      ),
    );
  }
}
