import 'dart:math';

import 'package:elytra/core/uuid.dart';
import 'package:flutter_test/flutter_test.dart';

/// Random giả luôn trả giá trị lớn nhất: nextInt(n) = n - 1.
class _MaxRandom implements Random {
  @override
  bool nextBool() => true;
  @override
  double nextDouble() => 1;
  @override
  int nextInt(int max) => max - 1;
}

void main() {
  final re = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$');
  test('định dạng v4 và variant trên nhiều lần sinh', () {
    for (var i = 0; i < 200; i++) {
      expect(uuidV4(), matches(re));
    }
  });
  test('bit version/variant đúng cả khi random toàn 0xFF', () {
    expect(uuidV4(_MaxRandom()), 'ffffffff-ffff-4fff-bfff-ffffffffffff');
  });
  test('hai lần sinh khác nhau', () => expect(uuidV4() == uuidV4(), isFalse));
}
