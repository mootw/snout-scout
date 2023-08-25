import 'dart:convert';
import 'dart:typed_data';

import 'package:app/providers/data_provider.dart';
import 'package:app/screens/match_page.dart';
import 'package:app/screens/view_team_page.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:snout_db/config/surveyitem.dart';

class SnoutScoutSearch extends SearchDelegate {
  @override
  String get searchFieldLabel => 'Search Data';

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const BackButtonIcon(),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return search(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return search(context);
  }

  Widget search(BuildContext context) {
    List<Widget> results = [];

    DataProvider db = context.watch<DataProvider>();

    for (final team in db.event.teams) {
      if (query.isEmpty) {
        continue;
      }
      if (team.toString().contains(query)) {
        //Load the robot picture to show in the search if it is available
        Widget? robotPicture;
        final pictureData =
            db.event.pitscouting[team.toString()]?['robot_picture'];
        if (pictureData != null) {
          robotPicture = AspectRatio(
              aspectRatio: 1,
              child: Image.memory(
                  Uint8List.fromList(base64Decode(pictureData).cast<int>()),
                  fit: BoxFit.cover));
        }

        results.add(ListTile(
          leading: robotPicture,
          title: Text(team.toString()),
          subtitle: const Text("Team"),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => TeamViewPage(teamNumber: team)),
            );
          },
        ));
      }
    }

    for (final match in db.event.matches.values) {
      if (query.isEmpty) {
        continue;
      }
      if (match.description.toLowerCase().contains(query.toLowerCase())) {
        results.add(ListTile(
          title: Text(match.description.toString()),
          subtitle: const Text("Match"),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) =>
                      MatchPage(matchid: db.event.matchIDFromMatch(match))),
            );
          },
        ));
      }
    }

    //Search in pit scouting
    for (final team in db.event.teams) {
      if (query.isEmpty) {
        continue;
      }
      final pitScouting = db.event.pitscouting[team.toString()];
      if (pitScouting == null) {
        continue;
      }

      for (final item in pitScouting.entries) {
        
        final surveyItem = db.event.config.pitscouting
            .firstWhereOrNull((element) => element.id == item.key);
        if(surveyItem == null) {
          continue;
        }
        if (surveyItem.type == SurveyItemType.picture) {
          //Do not include image data.
          continue;
        }
        if (item.value.toString().toLowerCase().contains(query.toLowerCase())) {
          //Load the robot picture to show in the search if it is available
          Widget? robotPicture;
          final pictureData =
              db.event.pitscouting[team.toString()]?['robot_picture'];
          if (pictureData != null) {
            robotPicture = AspectRatio(
                aspectRatio: 1,
                child: Image.memory(
                    Uint8List.fromList(base64Decode(pictureData).cast<int>()),
                    fit: BoxFit.cover));
          }

          results.add(ListTile(
            leading: robotPicture,
            title: Text('${item.value}'),
            subtitle:
                Text("${team.toString()} scouting - ${surveyItem.label}"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => TeamViewPage(teamNumber: team)),
              );
            },
          ));
        }
      }
    }

    //Search in post match survey
    for (final match in db.event.matches.values) {
      if (query.isEmpty) {
        continue;
      }
      for (final robot in match.robot.entries) {
        for (final value in robot.value.survey.entries) {
          if (value.value.toString().toLowerCase().contains(query.toLowerCase())) {
            results.add(ListTile(
              title: Text(value.value.toString()),
              subtitle: Text("${match.description} - ${robot.key} - ${value.key}"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          MatchPage(matchid: db.event.matchIDFromMatch(match))),
                );
              },
            ));
          }
        }
      }
    }

    return ListView(children: results);
  }
}
