import 'dart:convert';

import 'package:app/api.dart';
import 'package:app/main.dart';
import 'package:app/team_list_tile.dart';
import 'package:flutter/material.dart';

class AllTeamsPage extends StatefulWidget {
  const AllTeamsPage({Key? key}) : super(key: key);

  @override
  State<AllTeamsPage> createState() => All_TeamsPageState();
}

class All_TeamsPageState extends State<AllTeamsPage> {
  Future<List<int>> lol() async {
    var teams = await apiClient.get(Uri.parse("${await getServer()}/teams"));
    var list = List<int>.from(jsonDecode(teams.body).map((x) => x));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<int>>(
        future: lol(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return ListView(
              shrinkWrap: true,
              children: [
                for (var team in snapshot.data!) TeamListTile(teamNumber: team),
              ],
            );
          }
          return Center(child: CircularProgressIndicator.adaptive());
        });
  }
}
