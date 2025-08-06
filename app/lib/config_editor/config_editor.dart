import 'dart:convert';

import 'package:app/data_submit_login.dart';
import 'package:app/providers/data_provider.dart';
import 'package:app/providers/identity_provider.dart';
import 'package:app/screens/edit_markdown.dart';
import 'package:app/style.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import 'package:snout_db/patch.dart';
import 'package:snout_db/snout_db.dart';

class ConfigEditorPage extends StatefulWidget {

  final EventConfig initialState;

  const ConfigEditorPage({super.key, this.initialState = const EventConfig(name: '', team: 6749, fieldImage: '')});

  @override
  State<ConfigEditorPage> createState() => _ConfigEditorPageState();
}

class _ConfigEditorPageState extends State<ConfigEditorPage> {

  late EventConfig config;

  @override
  void initState () {
    super.initState();
    // Deep copy the config (jank mode)
    config = EventConfig.fromJson(widget.initialState.toJson());
  }

  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        children: [
          // ListTile(
          //   title: Text('name'),
          //   subtitle: Text(config.name),
          // ),

          // ListTile(
          //   title: Text('tbaEventId'),
          //   subtitle: Text(config.tbaEventId ?? ''),
          // ),

          // ListTile(
          //   title: Text('tbaSecretKey'),
          //   subtitle: Text(config.tbaSecretKey ?? ''),
          // ),

          // ListTile(
          //   title: Text('fieldStyle'),
          //   subtitle: Text(config.fieldStyle.toString()),
          // ),

          // ListTile(
          //   title: Text('team'),
          //   subtitle: Text(config.team.toString()),
          // ),



          // Text('pitscouting'),
          // Text('matchscouting'),
          // Text('matchscouting.events'),
          // Text('matchscouting.processes'),
          // Text('matchscouting.survey'),
          // Text('matchscouting.properties'),
         
                    ListTile(
              title: const Text("Edit Docs"),
              leading: const Icon(Icons.book),
              onTap: () async {
                final identity = context.read<IdentityProvider>().identity;
                final dataProvider = context.read<DataProvider>();
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => EditMarkdownPage(
                          source: dataProvider.event.config.docs,
                        ),
                  ),
                );
                if (result != null) {
                  Patch patch = Patch(
                    identity: identity,
                    time: DateTime.now(),
                    path: Patch.buildPath(['config', 'docs']),
                    value: result,
                  );
                  //Save the scouting results to the server!!
                  if (context.mounted) {
                    await submitData(context, patch);
                  }
                }
              },
            ),

          ListTile(
              title: const Text(
                "Set Field Image (2:1 ratio, blue alliance left, scoring table bottom)",
              ),
              leading: const Icon(Icons.map),
              onTap: () async {
                final identity = context.read<IdentityProvider>().identity;
                String result;
                try {
                  final bytes = await pickOrTakeImageDialog(
                    context,
                    largeImageSize,
                  );
                  if (bytes != null) {
                    result = base64Encode(bytes);
                    Patch patch = Patch(
                      identity: identity,
                      time: DateTime.now(),
                      path: Patch.buildPath(['config', 'fieldImage']),
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
        ],
      ),
    );
  }
}