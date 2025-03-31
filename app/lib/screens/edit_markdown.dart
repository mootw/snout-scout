import 'package:app/widgets/confirm_exit_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class EditMarkdownPage extends StatefulWidget {
  const EditMarkdownPage({super.key, required this.source});

  final String source;

  @override
  State<EditMarkdownPage> createState() => _EditMarkdownPageState();
}

class _EditMarkdownPageState extends State<EditMarkdownPage> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.source);
  }

  @override
  Widget build(BuildContext context) {
    return ConfirmExitDialog(
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Edit Markdown"),
          actions: [
            IconButton(
              onPressed: () => Navigator.pop(context, _controller.text),
              icon: const Icon(Icons.save),
            ),
          ],
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                maxLines: 999,
                controller: _controller,
                onChanged: (cows) => setState(() {}),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: MarkdownBody(data: _controller.text),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
