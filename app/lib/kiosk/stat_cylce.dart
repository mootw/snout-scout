import 'dart:async';

import 'package:app/kiosk/auto_scroller.dart';
import 'package:app/providers/data_provider.dart';
import 'package:app/screens/analysis/boxplot_analysis.dart';
import 'package:app/screens/analysis/events_heatmaps.dart';
import 'package:app/screens/analysis/match_preview.dart';
import 'package:app/screens/analysis/pitscout_survey_analysis.dart';
import 'package:app/screens/analysis/postmatch_survey_analysis.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class KioskInfoCycle extends StatefulWidget {
  const KioskInfoCycle({super.key});

  @override
  State<KioskInfoCycle> createState() => _KioskInfoCycleState();
}

class _KioskInfoCycleState extends State<KioskInfoCycle> {
  late Timer _t;
  int _idx = 0;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(Duration(seconds: 40), (_) {
      displayNewStat();
    });
  }

  @override
  void dispose() {
    _t.cancel();
    super.dispose();
  }

  void displayNewStat() {
    setState(() {
      // eventually this will overflow
      _idx++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final nextMatch = data.event.nextMatch;

    final options = [
      // Show preview for next match
      if (nextMatch != null)
        AnalysisMatchPreview(
          red: nextMatch.red,
          blue: nextMatch.blue,
          matchLabel: nextMatch.label,
        ),

      // Pit Survey Analysis (each chart)
      AnalysisPitScouting(),

      // Match Recording survey analysis (each chart)
      AnalysisPostMatchSurvey(),

      // events heatmap analysis (each chart)
      AnalysisEventsHeatmap(),

      // consistency analysis chart, random stat (scroll?)
      BoxPlotAnalysis(),
    ];

    if (_idx >= options.length) {
      _idx = 0;
    }
    return AutoScroller(key: ValueKey(_idx), child: options[_idx]);
  }
}

