import 'dart:convert';

import 'package:app/widgets/confirm_exit_dialog.dart';
import 'package:flutter/material.dart';

class JSONEditor extends StatefulWidget {
  const JSONEditor({super.key, required this.source, required this.validate});

  //Throws an exception if data is invalid
  final Function validate;
  final Object source;

  @override
  State<JSONEditor> createState() => _JSONEditorState();
}

class _JSONEditorState extends State<JSONEditor> {
  final _controller = TextEditingController();
  String _error = "";

  @override
  void initState() {
    super.initState();
    _controller.text = const JsonEncoder.withIndent(
      "    ",
    ).convert(widget.source);
  }

  @override
  Widget build(BuildContext context) {
    return ConfirmExitDialog(
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Edit"),
          actions: [
            IconButton(
              onPressed:
                  _error != ""
                      ? null
                      : () {
                        Navigator.of(context).pop(_controller.text);
                      },
              icon: const Icon(Icons.save),
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: TextField(
                maxLines: null,
                expands: true,
                controller: _controller,
                onChanged: (value) {
                  try {
                    widget.validate(json.decode(value));
                    setState(() {
                      _error = "";
                    });
                  } catch (e) {
                    setState(() {
                      _error = e.toString();
                    });
                  }
                },
              ),
            ),
            Text(
              _error,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ),
      ),
    );
  }
}
