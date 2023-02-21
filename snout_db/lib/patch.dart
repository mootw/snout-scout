//Handles applying and the schema for diffs

import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';
import 'package:rfc_6901/rfc_6901.dart';
import 'package:snout_db/event/frcevent.dart';

part 'patch.g.dart';

@JsonSerializable()
class Patch {

  //Time of the change
  DateTime time;
  //Where was the data changed??
  List<String> path;
  //JSON encoded data that this path should be patched with
  String data;

  Patch({required this.time, required this.path, required this.data});

  factory Patch.fromJson(Map<String, dynamic> json) => _$PatchFromJson(json);
  Map<String, dynamic> toJson() => _$PatchToJson(this);

  /// Patches a given database, throws an error if there is an issue.
  /// Returns a NEW instance of FRCEvent, it does not mutate the original
  FRCEvent patch (FRCEvent database) {
    var dbJson = jsonDecode(jsonEncode(database));
    final pointer = JsonPointer.build(path);
    dbJson = pointer.write(dbJson, jsonDecode(data));
    return FRCEvent.fromJson(jsonDecode(jsonEncode(dbJson)));
  }

}