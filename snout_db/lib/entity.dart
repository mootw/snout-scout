/// Primary container for data stored in the scouting app.
/// This could be a team, match, match survey, pit data, etc
/// treat it as a Map\<String, DataItem\>
class Entity {
  /// Unique Id of this entity
  String id;

  /// This is a special storage location where typically a pit map, or other "pit"/"event" related information goes like the schedule.
  Entity.pit() : id = '/pit';

  /// Typically where data scouted in the pit goes, shows on the team page
  Entity.team(int teamNumber) : id = '/team/$teamNumber';

  /// This is match data, like the score, actual start time, planning information, etc
  Entity.match(String matchId) : id = '/match/$matchId';

  Entity.matchTeam(String matchId, int teamNumber)
    : id = '/match/$matchId/team/$teamNumber';
}
