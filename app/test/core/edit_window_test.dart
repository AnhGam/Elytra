import 'package:elytra/core/edit_window.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ngày thứ 30 sửa được, ngày thứ 31 thì không', () {
    expect(withinEditWindow('2026-10-12', '2026-11-11'), isTrue); // 30 ngày
    expect(withinEditWindow('2026-10-11', '2026-11-11'), isFalse); // 31 ngày
    expect(withinEditWindow('2026-11-11', '2026-11-11'), isTrue);
    expect(withinEditWindow('2026-11-12', '2026-11-11'), isFalse); // tương lai
    expect(withinEditWindow('2026-13-01', '2026-11-11'), isFalse);
    expect(withinEditWindow('hôm qua', '2026-11-11'), isFalse);
  });
  test('shiftDate qua tháng và năm', () {
    expect(shiftDate('2026-03-01', -1), '2026-02-28');
    expect(shiftDate('2026-12-31', 1), '2027-01-01');
    expect(parseIsoDate('2026-02-30'), isNull);
    expect(() => shiftDate('abc', 1), throwsArgumentError);
  });
}
