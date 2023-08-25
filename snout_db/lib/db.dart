import 'package:collection/collection.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:snout_db/event/frcevent.dart';
import 'package:snout_db/patch.dart';

part 'db.g.dart';

@JsonSerializable(
  
)
class SnoutDB {
  
  /// read-only latest state of the event
  /// 
  /// **this value is exported toJson even though it is generated because of easier data export**
  @JsonKey(includeToJson: true)
  FRCEvent get event => _event;
  FRCEvent _event;

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
  }) : _event = FRCEvent.fromPatches(patches);

  factory SnoutDB.fromJson(Map<String, dynamic> json) =>
      _$SnoutDBFromJson(json);
  Map<String, dynamic> toJson() => _$SnoutDBToJson(this);


  void addPatch (Patch p) {
    patches.add(p);
    _event = p.patch(_event);
  }

  /// returns the last patch for a specific path.
  /// this is effectively the last edit time..
  /// HOWEVER this does not account for sub-edits
  /// we will ignore this for now...
  Patch? getLastPatchFor(List<String> pointer) {
    return patches.lastWhereOrNull((patch) => ListEquality().equals(pointer, patch.path));
  }
}
