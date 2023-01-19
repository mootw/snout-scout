import 'dart:async';

import 'package:app/durationformat.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TimeDuration extends StatefulWidget {
  const TimeDuration(
      {super.key, required this.time, this.displayDurationDefault = false});

  final DateTime time;
  final bool displayDurationDefault;

  @override
  State<TimeDuration> createState() => _TimeDurationState();
}

class _TimeDurationState extends State<TimeDuration> {
  late Timer t;

  @override
  void initState() {
    super.initState();
    t = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (widget.displayDurationDefault) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    t.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String primaryText = "";
    String secondaryText = "";

    if (widget.displayDurationDefault) {
      secondaryText = DateFormat.jm().format(widget.time.toLocal());
      primaryText = formatDuration(widget.time.difference(DateTime.now()));
    } else {
      primaryText = DateFormat.jm().format(widget.time.toLocal());
      secondaryText = formatDuration(widget.time.difference(DateTime.now()));
    }

    return Tooltip(
      message: secondaryText,
      child: Text(primaryText),
    );
  }
}
