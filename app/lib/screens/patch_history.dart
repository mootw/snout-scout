


import 'dart:convert';

import 'package:app/providers/data_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class PatchHistoryPage extends StatefulWidget {
  const PatchHistoryPage({super.key});

  @override
  State<PatchHistoryPage> createState() => _PatchHistoryPageState();
}

class _PatchHistoryPageState extends State<PatchHistoryPage> {
  @override
  Widget build(BuildContext context) {
    final patches = context.watch<DataProvider>().database.patches.reversed.toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit History"),
      ),
      body: ListView.builder(
        itemCount: patches.length,
        itemBuilder: 
      (context, index) {
        final patch = patches[index];
        return ListTile(
          title: Text('${patches.length - index}: ${patch.identity}'),
          onTap: () => showDialog(context: context, builder: (_) => AlertDialog(
            content: SingleChildScrollView(child: SelectableText(json.encode(patch))),
          )),
          subtitle: Text(patch.path),
          trailing: Text(DateFormat.jms().add_yMd().format(patch.time)),
        );
      }),
    );
  }
}