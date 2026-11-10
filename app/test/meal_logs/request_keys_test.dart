import 'package:elytra/core/meal_time.dart';
import 'package:elytra/features/meal_logs/meal_log_models.dart';
import 'package:elytra/features/meal_logs/request_keys.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('giữ khoá khi y nguyên, đổi khi khác, bỏ khi thành công', () {
    var n = 0;
    final k = RequestKeys(newId: () => 'k${n++}');
    const a = LogRequest.recipe(refId: 'r', servings: 1, meal: MealType.lunch, date: '2026-11-11');
    expect(k.keyFor(a), 'k0');
    expect(k.keyFor(a), 'k0');
    expect(
        k.keyFor(const LogRequest.recipe(
            refId: 'r', servings: 1.5, meal: MealType.lunch, date: '2026-11-11')),
        'k1');
    expect(
        k.keyFor(const LogRequest.recipe(
            refId: 'r', servings: 1.5, meal: MealType.dinner, date: '2026-11-11')),
        'k2');
    k.succeeded();
    expect(k.keyFor(a), 'k3');
  });

  test('cờ lỗi mạng bật khi markNetworkError, tắt khi succeeded', () {
    final k = RequestKeys(newId: () => 'x');
    expect(k.hadNetworkError, isFalse);
    k.markNetworkError();
    expect(k.hadNetworkError, isTrue);
    k.succeeded();
    expect(k.hadNetworkError, isFalse);
  });

  test('mặc định sinh UUID v4', () {
    final k = RequestKeys();
    const a = LogRequest.dish(refId: 'd', amountG: 100, meal: MealType.lunch, date: '2026-11-11');
    expect(k.keyFor(a), matches(RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-')));
  });
}
