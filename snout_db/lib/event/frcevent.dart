import 'package:json_annotation/json_annotation.dart';
import 'package:snout_db/event/pitscoutresult.dart';
import 'match.dart';

part 'frcevent.g.dart';

@JsonSerializable()
class FRCEvent {
  
  String name;
  List<int> teams;
  List<FRCMatch> matches;
  Map<String, PitScoutResult> pitscouting;


  //Returns sorted matches
  get sortedMatches => matches.sort((a, b) => a.scheduledTime.difference(b.scheduledTime).inMilliseconds);

  FRCEvent({required this.name, required this.teams, required this.matches, required this.pitscouting});

  factory FRCEvent.fromJson(Map<String, dynamic> json) => _$FRCEventFromJson(json);
  Map<String, dynamic> toJson() => _$FRCEventToJson(this);

  //Helpers
  List<FRCMatch> matchesWithTeam (int team) => matches.where((match) => match.hasTeam(team)).toList();
}
