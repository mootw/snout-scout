import 'package:app/main.dart';
import 'package:app/screens/match_recorder.dart';
import 'package:flutter/material.dart';
import 'package:snout_db/season/matchevent.dart';

//Ratio of width to height
double mapRatio = 0.5;

double robotSize = 31 / 649;

//General display widget for a field.
///NOTE: DO NOT constrain this widget, as it will lose its aspect ratio
class FieldMapViewer extends StatelessWidget {
  final Function(RobotPosition) onTap;

  final RobotPosition? robotPosition;

  final List<MatchEvent>? events;

  const FieldMapViewer(
      {required this.onTap, this.events, this.robotPosition, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    //Limit the view to the aspect ratio of the map
    //to prevent layout or touch detection oddity.
    return AspectRatio(
      aspectRatio: 1 / mapRatio,
      child: LayoutBuilder(builder: (context, constraints) {
        return SizedBox(
          child: GestureDetector(
            onTapDown: (details) {
              onTap(RobotPosition(
                  details.localPosition.dx / constraints.maxWidth,
                  1 -
                      details.localPosition.dy /
                          (constraints.maxWidth * mapRatio)));
            },
            child: Stack(
              children: [
                Center(
                  child: Image.network("${snoutData.serverURL}/field_map.png"),
                ),
                if (robotPosition != null)
                  Container(
                    alignment: Alignment(
                        ((robotPosition!.x * 2) - 1) *
                            (1 + ((robotSize * constraints.maxWidth) / constraints.maxWidth)),
                        -((robotPosition!.y * 2) - 1) *
                            (1 + ((robotSize * constraints.maxWidth) / constraints.maxHeight))),
                    child: Container(
                      width: robotSize * constraints.maxWidth,
                      height: robotSize * constraints.maxWidth,
                      color: Colors.black,
                      child: Icon(Icons.smart_toy,
                          size: robotSize * constraints.maxWidth - 2,
                          color: Theme.of(context).colorScheme.primary),
                    ),
                  ),
                if (events != null)
                  ...widgetFromEvents(context, events!),
              ],
            ),
          ),
        );
      }),
    );
  }
}

List<Widget> widgetFromEvents(BuildContext context, List<MatchEvent> events) {
  var widgets = <Widget>[];

  RobotPosition? lastEventPosition;

  for (final event in events) {
    if (event.data['type'] == "robot_position") {
      lastEventPosition =
          RobotPosition(event.getNumber("x"), event.getNumber("y"));
    }
    if (lastEventPosition != null) {
      widgets.add(Container(
        alignment: Alignment(
            ((lastEventPosition.x * 2) - 1), -((lastEventPosition.y * 2) - 1)),
        child: Icon(Icons.smart_toy,
            color: Theme.of(context).colorScheme.primary, size: robotSize),
      ));
    }
  }

  return widgets;
}
