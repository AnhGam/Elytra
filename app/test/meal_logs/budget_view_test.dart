import 'package:elytra/features/meal_logs/budget_view.dart';
import 'package:elytra/features/meal_logs/meal_log_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('progressRatio: chia 0 và vượt 100 %', () {
    expect(progressRatio(500, 0), 0);
    expect(progressRatio(500, null), 0);
    expect(progressRatio(2500, 2000), 1);
    expect(progressRatio(500, 2000), 0.25);
  });

  test('nhãn còn/vượt và tâm vòng', () {
    expect(gramRemainingLabel(61.6), 'Còn 61,6 g');
    expect(gramRemainingLabel(-12), 'Vượt 12 g');
    expect(overPct(2240, 1968), 14);
    expect(overPct(100, 0), 0);
    expect(isOver(2240, 1968), isTrue);
    expect(isOver(100, null), isFalse);
    final b = Budget.fromJson({
      'target': {'kcal': 1968},
      'consumed': {'kcal': 2118},
    });
    expect(ringCenter(b), (value: '150', caption: 'kcal vượt mức'));
    final c = Budget.fromJson({
      'target': {'kcal': 1968},
      'consumed': {'kcal': 1152},
    });
    expect(ringCenter(c), (value: '816', caption: 'kcal còn lại'));
    expect(formatKcal(1968), '1.968');
    expect(formatGram(130.0), '130');
    expect(formatGram(58.5), '58,5');
  });
}
