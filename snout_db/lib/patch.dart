//Handles applying and the schema for diffs

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
  final String path;

  /// data this path should be patched with.
  /// it is not encoded in a String because it will
  /// get decoded anyways and json is json
  /// IT IS POSSIBLE for the object to be explicitly null
  /// this is typically how a value gets 'deleted' or 'reset'
  final Object? value;

  /// this loosely follows RFC 6902
  /// TODO add op function
  Patch(
      {required this.identity,
      required this.time,
      required this.path,
      required this.value,});

  factory Patch.fromJson(Map json) => _$PatchFromJson(json);
  Map toJson() => _$PatchToJson(this);

  /// Patches a given database, throws an error if there is an issue.
  /// Returns a NEW instance of FRCEvent, it does not mutate the original
  FRCEvent patch(FRCEvent database) {
    var dbJson = database.toJson();
    dbJson = JsonPointer(path).write(dbJson, value)! as Map<dynamic, dynamic>;
    return FRCEvent.fromJson(dbJson);
  }

  /// This will ensure that the path is correctly escaped
  static String buildPath(List<String> tokens) =>
      JsonPointer.build(tokens).toString();

  /// will unescape 6901 path and convert to a list of String
  static Iterable<String> deconstructPath(String path) => path
      .split("/")
      .skip(1)
      .map((element) => element.replaceAll("~1", "/").replaceAll("~0", "~"));

  @override
  String toString() => toJson().toString();
}
