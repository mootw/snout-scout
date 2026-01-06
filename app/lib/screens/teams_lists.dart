import 'dart:convert';

import 'package:app/data_submit_login.dart';
import 'package:app/providers/data_provider.dart';
import 'package:app/providers/identity_provider.dart';
import 'package:app/screens/teams_page.dart';
import 'package:app/screens/view_team_page.dart';
import 'package:app/services/snout_image_cache.dart';
import 'package:app/widgets/team_avatar.dart';
import 'package:cbor/cbor.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snout_db/actions/strategy/write_team_list.dart';
import 'package:snout_db/strategy/team_list.dart';

Future removeDraft(TeamList item) async {
  final prefs = await SharedPreferences.getInstance();
  final drafts = prefs.getStringList('drafts') ?? <String>[];
  final decoded = drafts
      .map((e) => TeamList.fromCbor(cbor.decode(base64.decode(e)) as CborMap))
      .where((e) => e.name != item.name)
      .toList();
  prefs.setStringList(
    'drafts',
    decoded.map((e) => base64.encode(cbor.encode(e.toCbor()))).toList(),
  );
}

class TeamListsPage extends StatefulWidget {
  const TeamListsPage({super.key});

  @override
  State<TeamListsPage> createState() => _TeamListsPageState();
}

class _TeamListsPageState extends State<TeamListsPage> {
  List<TeamList> _draftLists = [];

  @override
  void initState() {
    super.initState();

    _loadDrafts();
  }

  Future _loadDrafts() {
    // Load draft list if it exists
    return SharedPreferences.getInstance().then((prefs) {
      final drafts = prefs.getStringList('drafts');
      if (drafts != null) {
        final draftLists = <TeamList>[];
        for (final item in drafts) {
          try {
            final decoded = base64.decode(item);
            final cborData = cbor.decode(decoded);
            final list = TeamList.fromCbor(cborData as CborMap);
            draftLists.add(list);
          } catch (e, s) {
            Logger.root.warning("Failed to load draft team list", e, s);
          }
        }
        if (mounted) {
          setState(() {
            _draftLists = draftLists;
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>().database;

    final lists = data.event.teamLists;

    final alias = data.aliases[context.read<IdentityProvider>().identity];

    return ListView(
      children: [
        if (_draftLists.isNotEmpty)
          for (final teamList in _draftLists)
            ListTile(
              leading: IconButton(
                onPressed: () async {
                  await removeDraft(teamList);
                  await _loadDrafts();
                },
                icon: Icon(Icons.delete),
              ),
              title: Text(
                'DRAFT: ${teamList.name} (${teamList.teams.length} teams)',
              ),
              subtitle: Text(teamList.description),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditTeamList(initialList: teamList),
                ),
              ).then((_) => _loadDrafts()),
            ),
        for (final teamList in lists.values)
          ListTile(
            title: Text('${teamList.name} (${teamList.teams.length} teams)'),
            subtitle: Text(teamList.description),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EditTeamList(initialList: teamList),
              ),
            ).then((_) => _loadDrafts()),
          ),

        Center(
          child: FilledButton.tonalIcon(
            label: Text('New Team List'),
            icon: Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditTeamList(
                    initialList: TeamList(
                      name: alias != null ? '$alias\'s List' : 'New List',
                      description: '',
                      teams: [],
                    ),
                  ),
                ),
              ).then((_) => _loadDrafts());
            },
          ),
        ),
      ],
    );
  }
}

class EditTeamList extends StatefulWidget {
  final TeamList initialList;
  const EditTeamList({super.key, required this.initialList});

  @override
  State<EditTeamList> createState() => _EditTeamListState();
}

class _EditTeamListState extends State<EditTeamList> {
  late TeamList _list;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _list = TeamList(
      name: widget.initialList.name,
      description: widget.initialList.description,
      teams: widget.initialList.teams
          .map((e) => TeamListEntry(team: e.team, description: e.description))
          .toList(),
    );
    _nameController.text = _list.name;
    _descriptionController.text = _list.description;
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    return WillPopScope(
      onWillPop: () async {
        if (_list.teams.isEmpty) {
          return true;
        }
        final prefs = await SharedPreferences.getInstance();
        final drafts = prefs.getStringList('drafts') ?? <String>[];
        final decoded = drafts
            .map(
              (e) =>
                  TeamList.fromCbor(cbor.decode(base64.decode(e)) as CborMap),
            )
            .where((e) => e.name != _list.name)
            .toList();
        decoded.add(_list);
        prefs.setStringList(
          'drafts',
          decoded.map((e) => base64.encode(cbor.encode(e.toCbor()))).toList(),
        );
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              border: UnderlineInputBorder(),
              hintText: 'List Name',
            ),
            style: Theme.of(context).textTheme.titleLarge,
            onChanged: (_) {
              setState(() {
                _list.name = _nameController.text;
              });
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: () async {
                // final prefs = await SharedPreferences.getInstance();
                // prefs.remove('draft_list');

                if (context.mounted) {
                  final action = ActionWriteTeamList(_list);
                  //Save the scouting results to the server!!
                  await submitData(context, action);
                }
                await removeDraft(_list);

                Navigator.pop(context);
              },
            ),
            SizedBox(width: 8),
          ],
        ),
        body: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'List Description',
                ),
                maxLines: 2,
                style: Theme.of(context).textTheme.bodyMedium,
                onChanged: (_) {
                  setState(() {
                    _list.description = _descriptionController.text;
                  });
                },
              ),
            ),
            ReorderableListView(
              shrinkWrap: true,
              children: [
                for (final entry in _list.teams)
                  TeamListTileItem(
                    onDelete: () {
                      setState(() {
                        _list.teams.remove(entry);
                      });
                    },
                    key: ValueKey(entry.team),
                    entry: entry,
                    rank: _list.teams.indexOf(entry) + 1,
                    onChanged: (val) {
                      setState(() {
                        _list.teams[_list.teams.indexOf(entry)].description =
                            val;
                      });
                    },
                  ),
              ],
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (oldIndex < newIndex) {
                    newIndex -= 1;
                  }
                  final TeamListEntry item = _list.teams.removeAt(oldIndex);
                  _list.teams.insert(newIndex, item);
                });
              },
            ),
            Center(
              child: FilledButton.tonalIcon(
                onPressed: () async {
                  final result = await showDialog(
                    context: context,
                    builder: (context) => Scaffold(
                      appBar: AppBar(title: const Text("Add Team")),
                      body: Center(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: Wrap(
                            spacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            runAlignment: WrapAlignment.center,
                            children: [
                              // Only show the teams that aren't already in the list
                              for (final team
                                  in context
                                      .watch<DataProvider>()
                                      .event
                                      .teams
                                      .where(
                                        (e) =>
                                            _list.teams
                                                .map((t) => t.team)
                                                .contains(e) ==
                                            false,
                                      ))
                                TeamListTile(
                                  teamNumber: team,
                                  onTap: () {
                                    Navigator.pop(context, team);
                                  },
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                  if (result != null &&
                      _list.teams.any((element) => element.team == result) ==
                          false) {
                    setState(() {
                      _list.teams.add(
                        TeamListEntry(team: result, description: ''),
                      );
                    });
                  }
                },
                label: Text('Add Team'),
                icon: Icon(Icons.add),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TeamListTileItem extends StatefulWidget {
  final TeamListEntry entry;
  final int rank;
  final ValueChanged<String> onChanged;
  final VoidCallback onDelete;

  const TeamListTileItem({
    super.key,
    required this.entry,
    required this.rank,
    required this.onChanged,
    required this.onDelete,
  });

  @override
  State<TeamListTileItem> createState() => _TeamListTileItemState();
}

class _TeamListTileItemState extends State<TeamListTileItem> {
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(
      text: widget.entry.description,
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    return InkWell(
      key: ValueKey(widget.entry.team),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => TeamViewPage(teamNumber: widget.entry.team),
        ),
      ),
      child: SizedBox(
        height: 120,
        child: Row(
          children: [
            IconButton(icon: Icon(Icons.delete), onPressed: widget.onDelete),
            SizedBox(
              width: 40,
              child: Text(
                '${widget.rank}',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: () {
                final pictureData =
                    data.event.pitscouting[widget.entry.team
                        .toString()]?[robotPictureReserved];
                if (pictureData != null) {
                  return AspectRatio(
                    aspectRatio: 1,
                    child: Image(
                      image: memoryImageProvider(pictureData),
                      fit: BoxFit.cover,
                    ),
                  );
                }
                return const SizedBox();
              }(),
            ),
            const SizedBox(width: 8),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FRCTeamAvatar(teamNumber: widget.entry.team, size: 42),
                Text(widget.entry.team.toString()),
              ],
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                onChanged: (value) {
                  widget.entry.description = value;
                  widget.onChanged(value);
                },
              ),
            ),
            // Space for drag handle
            const SizedBox(width: 48),
          ],
        ),
      ),
    );
  }
}
