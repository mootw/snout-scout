import 'package:app/screens/analysis/boxplot.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('quartiles math', () {
    test('even', () {
      expect(getQuartiles([5, 7, 4, 4, 6, 2, 8]), (
        min: 2,
        lower: 4,
        median: 5,
        upper: 7,
        max: 8,
      ));
    });
    test('combined', () {
      expect(getQuartiles([1, 3, 3, 4, 5, 6, 6, 7, 8, 8]), (
        min: 1,
        lower: 3,
        median: 5.5,
        upper: 7,
        max: 8,
      ));
    });
    test('odd', () {
      expect(getQuartiles([4, 17, 7, 14, 18, 12, 3, 16, 10, 4, 4, 11]), (
        min: 3,
        lower: 4,
        median: 10.5,
        upper: 15,
        max: 18,
      ));
    });
    test('empty', () {
      expect(() => getQuartiles([]), throwsA(dynamic));
    });
    test('1 value', () {
      expect(getQuartiles([1]), (
        min: 1,
        lower: 1,
        median: 1,
        upper: 1,
        max: 1,
      ));
    });
  });
}
