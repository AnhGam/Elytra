import 'package:elytra/core/vn_date.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('thứ dài và ngắn', () {
    // 10/11/2026 là thứ Ba
    expect(weekdayLong(DateTime.utc(2026, 11, 10)), 'Thứ Ba');
    expect(weekdayShort(DateTime.utc(2026, 11, 10)), 'T3');
    expect(weekdayLong(DateTime.utc(2026, 11, 15)), 'Chủ Nhật');
    expect(weekdayShort(DateTime.utc(2026, 11, 15)), 'CN');
    expect(weekdayShort(DateTime.utc(2026, 11, 9)), 'T2');
  });

  test('dòng ngày ở Dashboard', () {
    expect(longDateLabel(DateTime.utc(2026, 11, 10, 19)), 'Thứ Ba, 10 tháng 11');
    expect(longDateLabel(DateTime.utc(2026, 1, 4)), 'Chủ Nhật, 4 tháng 1');
  });
}
