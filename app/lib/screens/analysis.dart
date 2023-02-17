
import 'package:app/main.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';

class AnalysisPage extends StatefulWidget {
  const AnalysisPage({Key? key}) : super(key: key);

  @override
  State<AnalysisPage> createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage> {
  @override
  Widget build(BuildContext context) {
    return ListView(
      shrinkWrap: true,
      children: [
        FilledButton.tonal(onPressed: () {
          String url = Uri.parse(serverURL).pathSegments[1];

          launchUrlString("https://www.thebluealliance.com/event/${url.substring(0, url.length-5)}#rankings");
        }, child: Text("View rankings on TBA")),
        Text("Scoreboard (shows average value of all metrics for each team, like heatmaps) - Metrics Explorer - Match Predictor - Maybe allow for more 'sql' like queries here?? Performance comparison between two teams and their relative score when matched against each-other"),
      ],
    );
  }
}