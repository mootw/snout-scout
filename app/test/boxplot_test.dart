import 'package:app/screens/analysis/boxplot.dart';
import 'package:flutter_test/flutter_test.dart';

main() {
  group('quartiles math', () {
    test('even', () {
      expect(getQuartiles([5, 7, 4, 4, 6, 2, 8]), [2, 4, 5, 7, 8]);
    });
    test('combined', () {
      expect(getQuartiles([1, 3, 3, 4, 5, 6, 6, 7, 8, 8]), [1, 3, 5.5, 7, 8]);
    });
    test('odd', () {
      expect(getQuartiles([4, 17, 7, 14, 18, 12, 3, 16, 10, 4, 4, 11]),
          [3, 4, 10.5, 15, 18]);
    });
    test('empty', () {
      expect(() => getQuartiles([]),
          throwsA(dynamic));
    });
    test('1 value', () {
      expect(getQuartiles([1]),
          [1, 1, 1, 1, 1]);
    });
  });
}
