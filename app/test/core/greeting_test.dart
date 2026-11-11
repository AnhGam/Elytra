import 'package:elytra/core/greeting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('displayName bỏ email, rỗng, null', () {
    expect(displayName(null), isNull);
    expect(displayName('   '), isNull);
    expect(displayName('24521740@gm.uit.edu.vn'), isNull);
    expect(displayName('  Nguyễn Văn Thuận '), 'Nguyễn Văn Thuận');
  });
  test('shortName và avatarInitial lấy từ cuối', () {
    expect(shortName('Nguyễn Văn Thuận'), 'Thuận');
    expect(shortName('An'), 'An');
    expect(avatarInitial('nguyễn văn thuận'), 'T');
  });
  test('greeting theo mốc giờ', () {
    String at(int h, int m) => greeting(DateTime.utc(2026, 11, 11, h, m));
    expect(at(4, 0), 'Chào buổi sáng');
    expect(at(10, 59), 'Chào buổi sáng');
    expect(at(11, 0), 'Chào buổi trưa');
    expect(at(13, 59), 'Chào buổi trưa');
    expect(at(14, 0), 'Chào buổi chiều');
    expect(at(17, 59), 'Chào buổi chiều');
    expect(at(18, 0), 'Chào buổi tối');
    expect(at(3, 59), 'Chào buổi tối');
  });
}
