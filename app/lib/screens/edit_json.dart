import 'dart:convert';

import 'package:app/confirm_exit_dialog.dart';
import 'package:flutter/material.dart';

class JSONEditor extends StatefulWidget {
  const JSONEditor({super.key, required this.source, required this.validate});

  //Throws an exception if data is invalid
  final Function validate;
  final String source;

  @override
  State<JSONEditor> createState() => _JSONEditorState();
}

class _JSONEditorState extends State<JSONEditor> {
  final _controller = TextEditingController();

  String error = "";

  @override
  void initState() {
    super.initState();
    _controller.text = widget.source;
  }

  @override
  Widget build(BuildContext context) {
    return ConfirmExitDialog(
      child: Scaffold(
        appBar: AppBar(title: const Text("Edit"), actions: [
          IconButton(onPressed: error != "" ? null :
          () {
            Navigator.of(context).pop(_controller.text);
          }, icon: const Icon(Icons.save))
        ],),
        body: Column(
          children: [
            Expanded(
              child: TextField(
                maxLines: null,
                expands: true,
                controller: _controller,
                onChanged: (value) {
                  try {
                    widget.validate(jsonDecode(value));
                    setState(() {
                      error = "";
                    });
                  } catch (e) {
                    setState(() {
                      error = e.toString();
                    });
                  }
                },
              ),
            ),
            Text(error, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
        ),
      ),
    );
  }
}
