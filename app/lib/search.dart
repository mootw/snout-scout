




import 'package:app/main.dart';
import 'package:app/screens/match_page.dart';
import 'package:app/screens/view_team_page.dart';
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
      onPressed: () {
        close(context, null);
      },
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

  Widget search (BuildContext context) {
    List<Widget> results = [];

    EventDB db = context.watch<EventDB>();

    for(var team in db.db.teams) {
      if(query.isEmpty) {
        continue;
      }
      if(team.toString().contains(query)) {
        results.add(
          ListTile(
            title: Text(team.toString()),
            subtitle: const Text("Team"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => TeamViewPage(teamNumber: team)),
              );
            },
          )
        );
      }
    }

    for(var match in db.db.matches.values) {
      if(query.isEmpty) {
        continue;
      }
      if(match.description.toLowerCase().contains(query.toLowerCase())) {
        results.add(
          ListTile(
            title: Text(match.description.toString()),
            subtitle: const Text("Match"),
            onTap: () {
              Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      MatchPage(matchid: db.db.matchIDFromMatch(match))),
            );
            },
          )
        );
      }
    }

    //Search in pit scouting
    for(var team in db.db.teams) {
      if(query.isEmpty) {
        continue;
      }
      final pitScouting = db.db.pitscouting[team.toString()];
      if(pitScouting == null) {
        continue;
      }

      for(var item in pitScouting.entries) {
        final surveyItem = db.db.config.pitscouting.firstWhere((element) => element.id == item.key);
        if(surveyItem.type == SurveyItemType.picture) {
          //Do not include image data.
          continue;
        }

        if(item.value.toString().toLowerCase().contains(query.toLowerCase())) {
          results.add(
          ListTile(
            title: Text('${item.value}'),
            subtitle: Text("${team.toString()} Pit Scouting - ${surveyItem.label}"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => TeamViewPage(teamNumber: team)),
              );
            },
          )
        );
        }
      }
    }

    return ListView(children: results);
  }



}
