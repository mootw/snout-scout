import 'package:app/widgets/datasheet.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

({num min, num lower, num median, num upper, num max}) getQuartiles(
  List<num> numbers,
) {
  assert(numbers.isNotEmpty);
  final nums = numbers.toList();
  nums.sort();
  num getPart(double percent) {
    final index = (nums.length - 1) * percent;
    bool isExactNumber = (index % 1) == 0;
    if (isExactNumber) {
      return nums[index.floor()];
    } else {
      //calculate average of the number above and the number below
      return (nums[index.floor()] + nums[index.ceil()]) / 2;
    }
  }

  //Get the median before modifying the list
  final median = getPart(0.5);

  if (nums.length % 2 == 0) {
    nums.removeAt((nums.length / 2).floor());
  }

  return (
    min: nums.first,
    lower: getPart(0.25),
    median: median,
    upper: getPart(0.75),
    max: nums.last,
  );
}

/// Renders a box plot given a set of values
class BoxPlot extends StatelessWidget {
  final num min;
  final num max;

  final List<num> values;

  const BoxPlot({
    super.key,
    required this.values,
    required this.min,
    required this.max,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: BoxPlotPainter(this));
  }
}

class BoxPlotPainter extends CustomPainter {
  BoxPlot boxPlotData;

  BoxPlotPainter(this.boxPlotData);

  static double plotHeight = 8;

  @override
  void paint(Canvas canvas, Size size) {
    Paint p = Paint();
    p.color = Colors.white;
    p.strokeWidth = 1;
    p.style = PaintingStyle.stroke;

    //Only draw dot if there is 2 or less values
    if (boxPlotData.values.length <= 2) {
      p.strokeWidth = 3;
      for (final point in boxPlotData.values) {
        canvas.drawCircle(getOffset(size, point), 1, p);
      }
      return;
    }

    final quartiles = getQuartiles(boxPlotData.values);

    //Median
    canvas.drawLine(
      getOffset(size, quartiles.median) + Offset(0, plotHeight),
      getOffset(size, quartiles.median) + Offset(0, -plotHeight),
      p,
    );

    //1st and 3rd quartile
    canvas.drawRRect(
      RRect.fromLTRBR(
        getPercent(quartiles.lower) * size.width,
        (size.height / 2) + plotHeight,
        getPercent(quartiles.upper) * size.width,
        (size.height / 2) - plotHeight,
        Radius.zero,
      ),
      p,
    );

    final iqr = quartiles.upper - quartiles.lower;

    final maxWithinIQR = boxPlotData.values.lastWhereOrNull(
      (element) => element <= quartiles.upper + (iqr * 1.5),
    );
    final minWithinIQR = boxPlotData.values.firstWhereOrNull(
      (element) => element >= quartiles.lower - (iqr * 1.5),
    );

    //Top IQR
    if (maxWithinIQR != null) {
      canvas.drawLine(
        getOffset(size, quartiles.upper),
        getOffset(size, maxWithinIQR),
        p,
      );
      canvas.drawLine(
        getOffset(size, maxWithinIQR) + Offset(0, plotHeight / 2),
        getOffset(size, maxWithinIQR) + Offset(0, -plotHeight / 2),
        p,
      );
    }

    //bot IQR
    if (minWithinIQR != null) {
      canvas.drawLine(
        getOffset(size, quartiles.lower),
        getOffset(size, minWithinIQR),
        p,
      );
      canvas.drawLine(
        getOffset(size, minWithinIQR) + Offset(0, plotHeight / 2),
        getOffset(size, minWithinIQR) + Offset(0, -plotHeight / 2),
        p,
      );
    }

    //Outliers
    for (final point in boxPlotData.values) {
      if (point > quartiles.upper + (iqr * 1.5) ||
          point < quartiles.lower - (iqr * 1.5)) {
        canvas.drawCircle(getOffset(size, point), 2, p);
      }
    }

    // for (final point in boxPlotData.values) {
    //   canvas.drawCircle(getOffset(size, point), 1, p);
    // }
  }

  Offset getOffset(Size size, num input) =>
      Offset(size.width * getPercent(input), 0);

  getPercent(num input) =>
      (input - boxPlotData.min) / (boxPlotData.max - boxPlotData.min);

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true; //lol who cares about performance anyways!
  }
}

class BoxPlotLabelPainter extends CustomPainter {
  BoxPlot boxPlotData;
  double screenHeight;

  BoxPlotLabelPainter(this.boxPlotData, this.screenHeight);

  static double plotHeight = 8;
  static double divisions = 6;

  @override
  void paint(Canvas canvas, Size size) {
    Paint p = Paint();
    p.color = Colors.white54;
    p.strokeWidth = 0;
    p.style = PaintingStyle.stroke;

    final range = boxPlotData.max - boxPlotData.min;

    for (int i = 0; i <= divisions; i++) {
      final value = boxPlotData.min + ((range / divisions) * i);

      //Just draw the whole thing down the entire display height height
      canvas.drawLine(
        getOffset(size, value) + Offset(0, plotHeight + screenHeight),
        getOffset(size, value) + Offset(0, -plotHeight),
        p,
      );

      TextSpan span = TextSpan(
        style: const TextStyle(color: Colors.white),
        text: numDisplay(value),
      );
      TextPainter tp = TextPainter(
        text: span,
        textAlign: TextAlign.end,
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      tp.paint(canvas, getOffset(size, value) + Offset(4, -plotHeight));
    }
  }

  Offset getOffset(Size size, num input) =>
      Offset(size.width * getPercent(input), 0);

  getPercent(num input) =>
      (input - boxPlotData.min) / (boxPlotData.max - boxPlotData.min);

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true; //lol who cares about performance anyways!
  }
}
