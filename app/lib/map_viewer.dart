import 'package:app/main.dart';
import 'package:app/screens/match_recorder.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/framework.dart';

//Ratio of width to height
double map_ratio = 0.5;

double robot_size = 30;

//General display widget for a field.
///NOTE: DO NOT constrain this widget, as it will lose its aspect ratio 
class FieldMapViewer extends StatelessWidget {

  final Function(RobotPosition) onTap;
  
  final RobotPosition? robotPosition;

  const FieldMapViewer(
      {required this.onTap, this.robotPosition, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    //Limit the view to the aspect ratio of the map
    //to prevent layout or touch detection oddity.
    return AspectRatio(
      aspectRatio: 1 / map_ratio,
      child: LayoutBuilder(builder: (context, constraints) {
        return SizedBox(
          child: GestureDetector(
            onTapDown: (details) {
              onTap(RobotPosition(details.localPosition.dx / constraints.maxWidth,
                1 - details.localPosition.dy / (constraints.maxWidth * map_ratio)));
            },
            child: Stack(
              children: [
                Center(
                  child: Image.network("${snoutData.serverURL}/field_map.png"),
                ),
                if (robotPosition != null)
                  Container(
                    alignment: Alignment(((robotPosition!.x * 2) - 1) * (1 + (robot_size / constraints.maxWidth)),
                        -((robotPosition!.y * 2) - 1) * (1 + (robot_size / constraints.maxHeight))),
                    child: Container(
                      child: Icon(Icons.smart_toy, color: Theme.of(context).colorScheme.primary, size: robot_size)),
                  ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
