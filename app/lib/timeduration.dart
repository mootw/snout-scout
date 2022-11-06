


import 'package:app/durationformat.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TimeDuration extends StatefulWidget {

  const TimeDuration({super.key, required this.time, this.displayDurationDefault = false});

  final DateTime time;
  final bool displayDurationDefault;

  @override
  State<TimeDuration> createState() => _TimeDurationState();
}

class _TimeDurationState extends State<TimeDuration> {


  @override
  Widget build(BuildContext context) {

    String primaryText = "";
    String secondaryText = "";

    if(widget.displayDurationDefault) {
      primaryText = DateFormat.jm().format(widget.time.toLocal());
      secondaryText = formatDuration(widget.time.difference(DateTime.now()));
    } else {
      secondaryText = DateFormat.jm().format(widget.time.toLocal());
      primaryText = formatDuration(widget.time.difference(DateTime.now()));
    }

    return Tooltip(
      message: secondaryText,
      child: Text(primaryText),
    );
  }
}