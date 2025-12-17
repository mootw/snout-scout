import 'package:app/providers/data_provider.dart';
import 'package:app/screens/analysis/boxplot_analysis.dart';
import 'package:app/screens/analysis/events_heatmaps.dart';
import 'package:app/screens/analysis/heatmap_event_type.dart';
import 'package:app/screens/analysis/match_preview.dart';
import 'package:app/screens/analysis/pitscout_survey_analysis.dart';
import 'package:app/screens/analysis/postmatch_survey_analysis.dart';
import 'package:app/screens/analysis/table_match_properties.dart';
import 'package:app/screens/analysis/table_robot_recordings.dart';
import 'package:app/screens/analysis/table_team_averages.dart';
import 'package:app/screens/analysis/table_team_survey.dart';
import 'package:app/search.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher_string.dart';

class AnalysisPage extends StatefulWidget {
  const AnalysisPage({super.key});

  @override
  State<AnalysisPage> createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage> {
  @override
  Widget build(BuildContext context) {
    final tbaKey = context.watch<DataProvider>().event.config.tbaEventId;

    return ListView(
      children: [
        if (tbaKey != null)
          Align(
            alignment: Alignment.topLeft,
            child: FilledButton.tonal(
              onPressed: () => launchUrlString(
                "https://www.thebluealliance.com/event/$tbaKey#rankings",
              ),
              child: const Text("TBA Rankings"),
            ),
          ),
        ListTile(
          title: const Text("Search Raw Data"),
          leading: const Icon(Icons.search),
          onTap: () {
            showSearch(context: context, delegate: SnoutScoutSearch());
          },
        ),
        ListTile(
          title: const Text("Team Survey"),
          leading: const Icon(Icons.table_chart),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (builder) => const TableTeamSurvey()),
            );
          },
        ),
        ListTile(
          title: const Text("Team Averages"),
          leading: const Icon(Icons.table_chart),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (builder) => const TableTeamAveragesPage(),
              ),
            );
          },
        ),
        ListTile(
          title: const Text("Robot Recordings"),
          leading: const Icon(Icons.table_chart),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (builder) => const TableRobotRecordingsPage(),
              ),
            );
          },
        ),
        ListTile(
          title: const Text("Match Data"),
          leading: const Icon(Icons.table_chart),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (builder) => const TableMatchProperties(),
              ),
            );
          },
        ),
        ListTile(
          title: const Text("Consistency Analysis"),
          leading: const Icon(Icons.candlestick_chart_outlined),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (builder) => const BoxPlotAnalysis()),
            );
          },
        ),
        ListTile(
          title: const Text("Match Preview"),
          leading: const Icon(Icons.preview),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (builder) =>
                    const AnalysisMatchPreview(red: [], blue: []),
              ),
            );
          },
        ),
        ListTile(
          title: const Text("Heatmap by Event Type"),
          leading: const Icon(Icons.map),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (builder) => const AnalysisHeatMapByEventType(),
              ),
            );
          },
        ),
        ListTile(
          title: const Text("Event Heatmap Analysis"),
          leading: const Icon(Icons.map),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (builder) => const AnalysisEventsHeatmap(),
              ),
            );
          },
        ),
        ListTile(
          title: const Text("Pit Survey Analysis"),
          leading: const Icon(Icons.pie_chart),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (builder) => const AnalysisPitScouting(),
              ),
            );
          },
        ),
        ListTile(
          title: const Text("Match Recording Survey Analysis"),
          leading: const Icon(Icons.pie_chart),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (builder) => const AnalysisPostMatchSurvey(),
              ),
            );
          },
        ),
      ],
    );
  }
}
