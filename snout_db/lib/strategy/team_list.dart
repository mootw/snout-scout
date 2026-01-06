import 'package:cbor/cbor.dart';

/// List of teams with a name, description, and an ordered
/// list of team numbers and an associated String description
/// Lists are unique by their name
class TeamList {
  String name;
  String description;
  List<TeamListEntry> teams;

  TeamList({
    required this.name,
    required this.description,
    required this.teams,
  });

  CborValue toCbor() => CborMap({
    const CborSmallInt(1): CborString(name),
    const CborSmallInt(2): CborString(description),
    const CborSmallInt(3): CborList(teams.map((e) => e.toCbor()).toList()),
  });

  TeamList.fromCbor(CborMap map)
    : name = (map[const CborSmallInt(1)]! as CborString).toString(),
      description = (map[const CborSmallInt(2)]! as CborString).toString(),
      teams = ((map[const CborSmallInt(3)]! as CborList)
          .map((e) => TeamListEntry.fromCbor(e as CborMap))
          .toList());
}

class TeamListEntry {
  int team;
  String description;

  TeamListEntry({required this.team, required this.description});

  CborValue toCbor() => CborMap({
    const CborSmallInt(0): CborSmallInt(team),
    const CborSmallInt(1): CborString(description),
  });

  TeamListEntry.fromCbor(CborMap map)
    : team = (map[const CborSmallInt(0)]! as CborSmallInt).value,
      description = (map[const CborSmallInt(1)]! as CborString).toString();
}
