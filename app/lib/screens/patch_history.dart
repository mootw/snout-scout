import 'dart:convert';

import 'package:app/providers/data_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:snout_db/patch.dart';

class PatchHistoryPage extends StatefulWidget {
  final String? filter;

  const PatchHistoryPage({super.key, this.filter});

  @override
  State<PatchHistoryPage> createState() => _PatchHistoryPageState();
}

class _PatchHistoryPageState extends State<PatchHistoryPage> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.filter != null) {
      _controller.text = widget.filter!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final patches =
        context.watch<DataProvider>().database.patches.reversed.toList();

    final search = _controller.text;

    final filteredPatches = patches.where((patch) {
      if (search == "") {
        //empty search means all results
        //and im too lazy to create a separate code path
        return true;
      }
      if (patch.identity.contains(search)) {
        return true;
      }
      if (patch.path.contains(search)) {
        return true;
      }

      return false;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          onChanged: (_) => setState(() {
            //I KNOW THIS IS BAD PRACTICE
            //I ALSO DONT CARE TO FIX IT
          }),
          decoration: const InputDecoration(
            hintText: 'Ledger Filter',
          ),
        ),
      ),
      body: ListView.builder(
          itemCount: filteredPatches.length,
          itemBuilder: (context, index) {
            final patch = filteredPatches[index];
            return ListTile(
              title:
                  Text('${filteredPatches.length - index}: ${patch.identity}'),
              onTap: () => showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text("Close")),
                          TextButton(
                              onPressed: () {
                                final newPatchToApply = Patch(
                                  identity: patch.identity,
                                  path: patch.path,
                                  time: DateTime.now(),
                                  value: patch.value,
                                );
                                final snoutData = context.read<DataProvider>();
                                snoutData.newTransaction(newPatchToApply);
                                Navigator.pop(context);
                              },
                              child: const Text("Re-Submit Patch As NEW")),
                        ],
                        content: SingleChildScrollView(
                            child: SelectableText(json.encode(patch))),
                      )),
              subtitle: Text(patch.path),
              trailing: Text(DateFormat.jms().add_yMd().format(patch.time)),
            );
          }),
    );
  }
}
