import 'dart:async';

import 'package:app/providers/cache_memory_imageprovider.dart';
import 'package:app/providers/data_provider.dart';
import 'package:app/screens/match_page.dart';
import 'package:app/screens/view_team_page.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:snout_db/config/surveyitem.dart';
import 'package:snout_db/event/frcevent.dart';

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
    return SearchResultsWidget(query: query);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return SearchResultsWidget(query: query);
  }
}

class SearchResultsWidget extends StatefulWidget {
  final String query;

  const SearchResultsWidget({required this.query, super.key});

  @override
  State<SearchResultsWidget> createState() => _SearchResultsWidgetState();
}

class _SearchResultsWidgetState extends State<SearchResultsWidget> {
  List<WidgetBuilder> _results = [];
  StreamSubscription? _subscription;

  bool _loading = false;

  @override
  void didUpdateWidget(covariant SearchResultsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query) {
      _subscription?.cancel();

      print('uipdated wigdet ${widget.query}');
      setState(() {
        _results = [];
      });
      DataProvider db = context.read<DataProvider>();
      _subscription = search(db.event).listen((data) {
        print('got data');
        if (mounted) {
          setState(() {
            _results.add(data);
          });
        }
      });
      setState(() {
        _loading = true;
      });
      _subscription?.onDone(() => setState(() {
            _loading = false;
          }));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_loading) const LinearProgressIndicator(),
        Expanded(
          child: ListView(cacheExtent: 10000, children: [
            if (!_loading && _results.isEmpty)
              const Text('No Results. Try a different query'),
            for (final result in _results) result(context),
          ]),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Stream<WidgetBuilder> search(FRCEvent event) async* {
    for (final team in event.teams) {
      if (widget.query.runes.isEmpty) {
        continue;
      }
      if (team.toString().contains(widget.query)) {
        //Load the robot picture to show in the search if it is available
        Widget? robotPicture;
        final pictureData =
            event.pitscouting[team.toString()]?[robotPictureReserved];
        if (pictureData != null) {
          robotPicture = AspectRatio(
              aspectRatio: 1,
              child: Image(
                  image: CacheMemoryImageProvider(pictureData),
                  fit: BoxFit.cover));
        }
        yield (context) => ListTile(
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
            );
      }
    }

    for (final match in event.matches.values) {
      if (widget.query.isEmpty) {
        continue;
      }
      if (match.description
          .toLowerCase()
          .contains(widget.query.toLowerCase())) {
        yield (context) => ListTile(
              title: Text(match.description.toString()),
              subtitle: const Text("Match"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          MatchPage(matchid: event.matchIDFromMatch(match))),
                );
              },
            );
      }
    }

    //Search in pit scouting
    for (final team in event.teams) {
      if (widget.query.isEmpty) {
        continue;
      }
      final pitScouting = event.pitscouting[team.toString()];
      if (pitScouting == null) {
        continue;
      }

      for (final item in pitScouting.entries) {
        final surveyItem = event.config.pitscouting
            .firstWhereOrNull((element) => element.id == item.key);
        if (surveyItem == null) {
          continue;
        }
        if (surveyItem.type == SurveyItemType.picture) {
          //Do not include image data.
          continue;
        }
        if (item.value
            .toString()
            .toLowerCase()
            .contains(widget.query.toLowerCase())) {
          //Load the robot picture to show in the search if it is available
          Widget? robotPicture;
          final pictureData =
              event.pitscouting[team.toString()]?[robotPictureReserved];
          if (pictureData != null) {
            robotPicture = AspectRatio(
                aspectRatio: 1,
                child: Image(
                    image: CacheMemoryImageProvider(pictureData),
                    fit: BoxFit.cover));
          }

          await Future.delayed(const Duration(seconds: 0));
          yield (context) => ListTile(
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
              );
        }
      }
    }

    //Search in post match survey
    for (final match in event.matches.values) {
      if (widget.query.isEmpty) {
        continue;
      }
      for (final robot in match.robot.entries) {
        for (final value in robot.value.survey.entries) {
          final surveyItem = event.config.matchscouting.survey
              .firstWhereOrNull((element) => element.id == value.key);
          if (surveyItem?.type == SurveyItemType.picture) {
            //Do not include image data.
            continue;
          }

          if (value.value
              .toString()
              .toLowerCase()
              .contains(widget.query.toLowerCase())) {
            await Future.delayed(const Duration(seconds: 0));
            yield (context) => ListTile(
                  title: Text(value.value.toString()),
                  subtitle: Text(
                      "${match.description} - ${robot.key} - ${value.key}"),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => MatchPage(
                              matchid: event.matchIDFromMatch(match))),
                    );
                  },
                );
          }
        }
      }
    }
  }
}
