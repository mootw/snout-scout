import 'package:json_annotation/json_annotation.dart';
import 'package:snout_db/config/eventconfig.dart';
import 'package:snout_db/event/frcevent.dart';
import 'package:snout_db/patch.dart';

part 'db.g.dart';

@JsonSerializable()
class SnoutDB {

  /// latest state of the event (some clients will want this information)
  final FRCEvent event;

  /// history of all changes to the database, the entire database state can be constructed
  /// by applying the patches in order, both are stored together for convenience
  final List<Patch> patches;


  /// this is the primary DB file, this contains all of the information needed
  /// to reconstruct the scouting data. BECAUSE the scouting data has unique
  /// requirements to data integrity, metadata, and auditing, we cannot just store
  /// the latest state of the database (this would be the easiest thing to do)
  /// rather we need to store the entire history of the database. for convenience
  /// a client can request the latest state, or patches, or both from the server.
  /// other metadata might get stored here too.
  SnoutDB({
    required this.patches,
  }) : event = FRCEvent.fromPatches(patches);

  factory SnoutDB.fromJson(Map<String, dynamic> json) =>
      _$SnoutDBFromJson(json);
  Map<String, dynamic> toJson() => _$SnoutDBToJson(this);
}