



import 'package:app/fieldwidget.dart';
import 'package:flutter/material.dart';
import 'package:snout_db/snout_db.dart';

class DebugFieldPosition extends StatefulWidget {
  const DebugFieldPosition({super.key});

  @override
  State<DebugFieldPosition> createState() => _DebugFieldPositionState();
}

class _DebugFieldPositionState extends State<DebugFieldPosition> {
  
  FieldPosition? _selected;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selected.toString()),
      ),
      body: FieldPositionSelector(onTap: (pos) {
        setState(() {
          _selected = pos;
        });
      }, robotPosition: _selected, alliance: Alliance.tie, teamNumber: 0),
    );
  }
}