import 'dart:async';

import 'package:app/providers/data_provider.dart';
import 'package:app/screens/match_page.dart';
import 'package:app/screens/view_team_page.dart';
import 'package:app/services/snout_image_cache.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:snout_db/config/surveyitem.dart';
import 'package:snout_db/event/frcevent.dart';
import 'package:string_similarity/string_similarity.dart';

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
  final _results = <SearchResult>[];
  StreamSubscription? _subscription;

  bool _loading = false;

  @override
  void didUpdateWidget(covariant SearchResultsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query) {
      _subscription?.cancel();
      setState(() {
        _results.clear();
      });
      DataProvider db = context.read<DataProvider>();
      _subscription = throttledSearch(db.event).listen((data) {
        if (mounted) {
          setState(() {
            _results.add(data);
          });
          _results.sort();
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

  Stream<SearchResult> throttledSearch(FRCEvent event) async* {
    await for (final event in _search(event, widget.query.toLowerCase())) {
      yield event;
      // Throttle the search stream to unblock after each item.
      // This is not a perfect solution since a query with no results
      // That iterates through every item is still going to be slow.
      await Future.delayed(Duration.zero);
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
              ListTile(
                  title: Text(
                      'No Results. Try a different query like: "broke", "fast", or "disabled"')),
            for (final result in _results) result.builder(context),
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
}

class SearchResult implements Comparable<SearchResult> {
  final WidgetBuilder builder;
  final double quality;

  const SearchResult(this.quality, this.builder);

  @override
  int compareTo(SearchResult other) {
    return other.quality.compareTo(quality);
  }
}

Stream<SearchResult> _search(FRCEvent event, String query) async* {
  // Generally pretty low since we want more results than not..
  const double threshold = 0.5;

  for (final team in event.teams) {
    if (query.runes.isEmpty) {
      continue;
    }

    final quality = team.toString().startsWith(query)
        ? 1
        : (team.toString().contains(query) ? 0.9 : -1);
    if (quality >= 0) {
      //Load the robot picture to show in the search if it is available
      Widget? robotPicture;
      final pictureData =
          event.pitscouting[team.toString()]?[robotPictureReserved];
      if (pictureData != null) {
        robotPicture = AspectRatio(
            aspectRatio: 1,
            child: Image(
                image: snoutImageCache.getCached(pictureData),
                fit: BoxFit.cover));
      }
      yield SearchResult(
          quality.toDouble(),
          (context) => ListTile(
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

  for (final match in event.schedule.values) {
    if (query.isEmpty) {
      continue;
    }
    final quality = match.label.toLowerCase().similarityTo(query);
    if (quality >= 0.8) {
      yield SearchResult(
          quality,
          (context) => ListTile(
                title: Text(match.label),
                subtitle: const Text("Match"),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => MatchPage(matchid: match.id)),
                  );
                },
              ));
    }
  }

  //Search in pit scouting
  for (final team in event.teams) {
    if (query.isEmpty) {
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
      final quality =
          _fuzzyMatchSentence(item.value.toString().toLowerCase(), query);
      if (quality >= threshold) {
        //Load the robot picture to show in the search if it is available
        Widget? robotPicture;
        final pictureData =
            event.pitscouting[team.toString()]?[robotPictureReserved];
        if (pictureData != null) {
          robotPicture = AspectRatio(
              aspectRatio: 1,
              child: Image(
                  image: snoutImageCache.getCached(pictureData),
                  fit: BoxFit.cover));
        }

        yield SearchResult(
            quality,
            (context) => ListTile(
                  leading: robotPicture,
                  title: Text('${item.value}'),
                  subtitle: Text("${team.toString()}: ${surveyItem.id}"),
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
  for (final match in event.matches.entries) {
    if (query.isEmpty) {
      continue;
    }
    for (final robot in match.value.robot.entries) {
      for (final value in robot.value.survey.entries) {
        final surveyItem = event.config.matchscouting.survey
            .firstWhereOrNull((element) => element.id == value.key);
        if (surveyItem?.type == SurveyItemType.picture) {
          //Do not include image data.
          continue;
        }

        final quality =
            _fuzzyMatchSentence(value.value.toString().toLowerCase(), query);

        if (quality >= threshold) {
          yield SearchResult(
              quality,
              (context) => ListTile(
                    title: Text(value.value.toString()),
                    subtitle: Text(
                        "${event.schedule[match.key]?.label}: ${robot.key}: ${value.key}"),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                MatchPage(matchid: match.key)),
                      );
                    },
                  ));
        }
      }
    }
  }
}

// 0 no match 1 = full match
double _fuzzyMatchSentence(String source, String query) {
  final sourceSegments = source.split(' ');

  double score = 0;

  for (final word in sourceSegments) {
    final match = word.similarityTo(query);
    if (match > score) {
      score = match;
    }
  }

  return score;
}
