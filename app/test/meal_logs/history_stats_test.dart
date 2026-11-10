import 'package:elytra/core/edit_window.dart';
import 'package:elytra/features/meal_logs/history_stats.dart';
import 'package:elytra/features/meal_logs/meal_log_models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/meal_log_fixtures.dart';

void main() {
  const today = '2026-11-10';
  final week = [
    hday('2026-11-04', 1900), hday('2026-11-05', 2240), hday('2026-11-06', 1780),
    hday('2026-11-07', 0, items: 0), hday('2026-11-08', 1990), hday('2026-11-09', 2050, target: 2200),
    hday(today, 1152),
  ];
  test('trung bình và ngày trong mục tiêu bỏ hôm nay và ngày trống', () {
    expect(averageKcal(week, today), closeTo((1900 + 2240 + 1780 + 1990 + 2050) / 5, 1e-9));
    expect(targetHits(week, today), (hits: 4, counted: 5)); // 2240 > 110 % → không tính
  });
  test('mục tiêu theo từng ngày', () {
    expect(inTarget(hday('d', 2050, target: 2200)), isTrue);
    expect(barKind(hday('d', 2200, target: 1968), today), BarKind.over);
    expect(barKind(hday('d', 2200, target: 2200), today), BarKind.normal);
  });
  test('cột và chấm', () {
    expect(barKind(week.last, today), BarKind.today);
    expect(dotKind(week[3], today), DotKind.none);
    expect(dotKind(week[1], today), DotKind.over);
    expect(dotKind(hday('d', 1000), today), DotKind.none); // dưới 90 %
    expect(dotKind(week[0], today), DotKind.ok);
  });
  test('dữ liệu toàn 0 không lỗi trục', () {
    final zeros = [for (var i = 0; i < 7; i++) hday(shiftDate(today, -i), 0, target: 0, items: 0)];
    expect(chartMaxY(zeros), 1000);
    expect(averageKcal(zeros, today), isNull);
    expect(macroAverages(zeros, today), isNull);
  });
  test('khoảng ngày và nhãn trục', () {
    expect(rangeEnding(today, 7), (from: '2026-11-04', to: today));
    expect(rangeEnding(today, 99).from, shiftDate(today, -30));
    expect(xLabelIndexes(30), [1, 8, 15, 22, 29]);
    expect(xLabelIndexes(7), [0, 1, 2, 3, 4, 5, 6]);
    expect(chartMaxY(week), 3000);
  });
  test('trung bình macro và % năng lượng', () {
    final days = [
      const HistoryDay(date: '2026-11-08', kcal: 2000, proteinG: 100, carbsG: 200, fatG: 40, itemCount: 2, targetKcal: 2000),
      const HistoryDay(date: '2026-11-09', kcal: 2000, proteinG: 120, carbsG: 220, fatG: 60, itemCount: 2, targetKcal: 2000),
      hday(today, 500),
    ];
    final m = macroAverages(days, today)!;
    expect(m.proteinG, 110);
    expect(m.carbsG, 210);
    expect(m.fatG, 50);
    // 440 / 1730, 840 / 1730, 450 / 1730
    expect((m.proteinPct, m.carbsPct, m.fatPct), (25, 49, 26));
  });
}
