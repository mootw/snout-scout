import 'package:json_annotation/json_annotation.dart';
import 'package:snout_db/config/matchscouting.dart';
import 'package:snout_db/config/surveyitem.dart';

part 'eventconfig.g.dart';

@JsonSerializable()
class EventConfig {
  /// Human readable name for this event (the one displayed on the status bar)
  final String name;

  /// year for this season; used to determine which field to display
  final int season;

  /// Event ID on TBA used to link rankings and other data (Optional)
  final String? tbaEventId;

  /// since scouting data is considered private, im not too concerned
  /// about secret sharing. Originally the plan was to store the API
  /// key on the server and have the server handle all requests
  /// (eventually it might just be a proxy), but having the client
  /// making requests makes sense for autofilling fields, and loading
  /// data in general. For instance, scouts might want to map certain data
  /// to autofill in multiple areas of the app (some might even be game)
  /// specific so having the raw responses to create those mappings makes
  /// sense too. however we do not want the server making its own patches
  /// using tba data because we do not want to lose any scouting data and
  /// want scouts to confirm all changes (thus auto-fill).
  final String? tbaSecretKey;

  /// Determines how the app will normalize event positions
  final FieldStyle fieldStyle;

  /// team number
  final int team;

  final List<SurveyItem> pitscouting;

  final MatchScouting matchscouting;

  const EventConfig(
      {required this.name,
      required this.team,
      required this.season,
      this.tbaEventId,
      this.tbaSecretKey,
      this.fieldStyle = FieldStyle.rotated,
      this.pitscouting = const [],
      this.matchscouting = const MatchScouting()});

  factory EventConfig.fromJson(Map<String, dynamic> json) =>
      _$EventConfigFromJson(json);
  Map<String, dynamic> toJson() => _$EventConfigToJson(this);
}

enum FieldStyle { rotated, mirrored }
