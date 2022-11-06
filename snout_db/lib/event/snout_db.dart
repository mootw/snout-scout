import 'package:json_annotation/json_annotation.dart';
import 'package:snout_db/event/frcevent.dart';

part 'snout_db.g.dart';

@JsonSerializable()
class SnoutDB {
  /// The generated code assumes these values exist in JSON.
  int version;

  /// The generated code below handles if the corresponding JSON value doesn't
  /// exist or is empty.
  Map<String, FRCEvent> events;

  SnoutDB({required this.version, required this.events});

  factory SnoutDB.fromJson(Map<String, dynamic> json) => _$SnoutDBFromJson(json);
  Map<String, dynamic> toJson() => _$SnoutDBToJson(this);
}