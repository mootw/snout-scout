//Data class that handles scouting tool things

import 'package:flutter/material.dart';

class ScoutingToolData {
  Map<String, dynamic> values;

  ScoutingToolData(this.values);

  get id {
    return values['id'];
  }

  get type {
    return values['type'];
  }

  get label {
    return values['label'];
  }

  get visualPriority {
    return values['visual_priority']?.toDouble() ?? 1;
  }

  get options {
    return List<String>.from(values["options"].map((x) => x));
  }

  get optionsValues {
    return List<int>.from(values["options_values"].map((x) => x));
  }

  double getNumber(String key) {
    return values[key].toDouble();
  }
}

class ScoutingToolWidget extends StatefulWidget {
  const ScoutingToolWidget({Key? key}) : super(key: key);

  @override
  State<ScoutingToolWidget> createState() => _ScoutingToolWidgetState();
}

class _ScoutingToolWidgetState extends State<ScoutingToolWidget> {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
