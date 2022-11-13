
import 'package:flutter/material.dart';

class AnalysisPage extends StatefulWidget {
  const AnalysisPage({Key? key}) : super(key: key);

  @override
  State<AnalysisPage> createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage> {
  @override
  Widget build(BuildContext context) {
    return const Text("Scoreboard (shows average value of all metrics for each team, like heatmaps) - Metrics Explorer - Match Predictor - Maybe allow for more 'sql' like queries here?? Performance comparison between two teams and their relative score when matched against each-other");
  }
}