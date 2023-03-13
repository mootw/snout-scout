import 'package:app/screens/analysis/events_heatmaps.dart';
import 'package:app/screens/analysis/match_preview.dart';
import 'package:app/screens/analysis/pitscout_survey_analysis.dart';
import 'package:app/screens/analysis/postmatch_survey_analysis.dart';
import 'package:flutter/material.dart';

class AnalysisPage extends StatefulWidget {
  const AnalysisPage({super.key});

  @override
  State<AnalysisPage> createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage> {

  @override
  Widget build(BuildContext context) {
    return ListView(children: [
      const Text(
          "Scoreboard (shows average value of all metrics for each team, like heatmaps) - Metrics Explorer - Maybe allow for more 'sql' like queries here??"),
      
      ListTile(
        title: const Text("Match Preview"),
        onTap: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (builder) => const AnalysisMatchPreview(red: [], blue: [])));
        },
      ),
      
      ListTile(
        title: const Text("Event Heatmap Analysis"),
        onTap: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (builder) => const AnalysisEventsHeatmap()));
        },
      ),
      ListTile(
        title: const Text("Scouting Survey Analysis"),
        onTap: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (builder) => const AnalysisPitScouting()));
        },
      ),
      ListTile(
        title: const Text("Post-Match Survey Analysis"),
        onTap: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (builder) => const AnalysisPostMatchSurvey()));
        },
      ),

      const Text(
              "Analysis PER data point (like box and whisper plots and Scatter plot)"),
    ]);
  }
}
