//Handles applying and the schema for diffs

import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';
import 'package:rfc_6901/rfc_6901.dart';
import 'package:snout_db/event/frcevent.dart';

part 'patch.g.dart';

@JsonSerializable()
class Patch {

  /// some unique string that identifies the patch creator
  /// in the future this could be cryptographically signed
  /// to prevent spoofing
  final String identity;

  /// time of the change
  final DateTime time;

  /// rfc_6901 JSON pointer in the scouting data
  /// when possible this should point as deeply as possible
  /// to avoid conflicts
  final List<String> pointer;

  /// data this path should be patched with.
  /// it is not encoded in a String because it will 
  /// get decoded anyways and json is json no need to "wrap it"
  final Object data;

  Patch(
      {required this.identity,
      required this.time,
      required this.pointer,
      required this.data});

  factory Patch.fromJson(Map<String, dynamic> json) => _$PatchFromJson(json);
  Map<String, dynamic> toJson() => _$PatchToJson(this);

  /// Patches a given database, throws an error if there is an issue.
  /// Returns a NEW instance of FRCEvent, it does not mutate the original
  FRCEvent patch(FRCEvent database) {
    var dbJson = jsonDecode(jsonEncode(database));
    final ptr = JsonPointer.build(pointer);
    dbJson = ptr.write(dbJson, data);
    return FRCEvent.fromJson(jsonDecode(jsonEncode(dbJson)));
  }
}
