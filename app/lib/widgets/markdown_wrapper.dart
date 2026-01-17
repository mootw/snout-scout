import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:url_launcher/url_launcher_string.dart';

class MarkdownText extends StatelessWidget {
  final String data;

  /// wraps the markdown package to add launching URLs
  const MarkdownText({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return MarkdownBody(
      data: data,
      onTapLink: (text, href, title) =>
          href != null ? launchUrlString(href) : null,
    );
  }
}
