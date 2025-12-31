import 'package:app/providers/data_provider.dart';
import 'package:app/widgets/scout_name_display.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class ActionChainHistoryPage extends StatefulWidget {
  final String? filter;

  const ActionChainHistoryPage({super.key, this.filter});

  @override
  State<ActionChainHistoryPage> createState() => _ActionChainHistoryPageState();
}

class _ActionChainHistoryPageState extends State<ActionChainHistoryPage> {
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
    final database = context.watch<DataProvider>().database;
    final actions = database.actions.reversed.toList();

    final search = _controller.text;

    final filteredPatches = actions.where((patch) {
      final chainAction = patch.payload;

      if (search == "") {
        //empty search means all results
        //and im too lazy to create a separate code path
        return true;
      }
      if (patch.author.toString().contains(search)) {
        return true;
      }
      if (chainAction.action.toString().contains(search)) {
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
          decoration: const InputDecoration(hintText: 'Ledger Filter'),
        ),
      ),
      body: ListView.builder(
        itemCount: filteredPatches.length,
        itemBuilder: (context, index) {
          final patch = filteredPatches[index];
          final chainAction = patch.payload;
          return ListTile(
            title: Text(
              '${actions.length - index}: ${chainAction.action.toString()}',
            ),
            subtitle: Align(
              alignment: Alignment.centerLeft,
              child: ScoutName(db: database, scoutPubkey: patch.author),
            ),
            trailing: Text(DateFormat.jms().add_yMd().format(chainAction.time)),
            onTap: () => showDialog(
              context: context,
              builder: (_) => AlertDialog(
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Close"),
                  ),
                ],
                content: SingleChildScrollView(
                  child: SelectableText(chainAction.action.toCbor().toString()),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
