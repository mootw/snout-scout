
import 'package:app/data/season_config.dart';






class TimelineEvent {

  int time;
  ScoutingToolData data;

  Map<String, dynamic> toJson() => {
    "time": time,
    "data": data.toJson(),
  };

  factory TimelineEvent.fromJson(Map<String, dynamic> json) =>
      TimelineEvent(
        time: json['time'],
        data: ScoutingToolData.fromJson(json['data']),
      );

  TimelineEvent({required this.time, required this.data});
}