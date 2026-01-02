import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:snout_db/config/data_item_schema.dart';
import 'package:snout_db/config/matchscouting.dart';

part 'eventconfig.g.dart';

@immutable
@JsonSerializable()
class EventConfig {
  /// Human readable name for this event (the one displayed on the status bar)
  final String name;

  /// Event ID on TBA used to link rankings and other data (Optional)
  final String? tbaEventId;

  /// since scouting data is considered private, im not too concerned
  /// about secret sharing. Originally the plan was to store the API
  /// key on the server and have the server handle all requests
  /// (eventually it might just be a proxy), but having the client
  /// making requests makes sense for autofilling fields and loading
  /// data in general. For instance, scouts might want to map certain data
  /// to autofill in multiple areas of the app (some might even be game)
  /// specific so having the raw responses to create those mappings makes
  /// sense too. however we do not want the server making its own patches
  /// using tba data because we do not want to lose any scouting data and
  /// want scouts to confirm all changes (thus "auto-fill").
  final String? tbaSecretKey;

  /// Determines how the app will normalize event positions
  final FieldStyle fieldStyle;

  /// team number
  final int team;

  // TODO rename this field before 2026
  final List<DataItemSchema> pitscouting;

  final List<DataItemSchema> pit;

  final MatchScouting matchscouting;

  final String fieldImage;

  const EventConfig({
    required this.name,
    required this.team,
    this.tbaEventId,
    this.tbaSecretKey,
    this.fieldStyle = FieldStyle.rotated,
    this.pitscouting = const [],
    this.pit = const [
      // Default values to inspire these pit data fields
      DataItemSchema(
        id: 'pit_map',
        label: 'Pit Map',
        type: DataItemType.picture,
        docs: 'Image of the Pit Map',
      ),
      DataItemSchema(
        id: 'docs',
        label: 'Docs',
        type: DataItemType.text,
        docs: 'Event schedule and other important info',
      ),
      DataItemSchema(
        id: 'fresh_battery',
        label: 'Fresh Battery',
        type: DataItemType.toggle,
      ),
    ],
    this.matchscouting = const MatchScouting(),
    // image is put last to make editing via text easier
    required this.fieldImage,
  });

  factory EventConfig.fromJson(Map<String, dynamic> json) =>
      _$EventConfigFromJson(json);
  Map<String, dynamic> toJson() => _$EventConfigToJson(this);
}

enum FieldStyle { rotated, mirrored }
