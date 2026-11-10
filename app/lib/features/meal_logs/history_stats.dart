import 'dart:math' as math;

import '../../core/edit_window.dart';
import 'meal_log_models.dart';

/// Khoảng [days] ngày kết thúc ở [today] (kẹp 1–31 ngày), gồm cả hai đầu.
({String from, String to}) rangeEnding(String today, int days) {
  final n = days.clamp(1, 31);
  return (from: shiftDate(today, -(n - 1)), to: today);
}

/// Ngày có ghi nhận và không phải hôm nay thì mới tính vào thống kê.
bool countsForStats(HistoryDay d, String today) =>
    (d.itemCount > 0 || d.kcal > 0) && d.date != today;

/// Trong mục tiêu: lệch không quá 10 % mục tiêu của chính ngày đó.
bool inTarget(HistoryDay d) =>
    d.targetKcal > 0 && (d.kcal - d.targetKcal).abs() <= 0.1 * d.targetKcal;

/// Trung bình kcal các ngày được tính; không có ngày nào thì null.
double? averageKcal(List<HistoryDay> days, String today) {
  final counted = days.where((d) => countsForStats(d, today)).toList();
  if (counted.isEmpty) return null;
  return counted.fold<double>(0, (s, d) => s + d.kcal) / counted.length;
}

/// Số ngày trong mục tiêu trên số ngày được tính.
({int hits, int counted}) targetHits(List<HistoryDay> days, String today) {
  final counted = days.where((d) => countsForStats(d, today)).toList();
  return (hits: counted.where(inTarget).length, counted: counted.length);
}

enum BarKind { normal, over, today }

BarKind barKind(HistoryDay d, String today) {
  if (d.date == today) return BarKind.today;
  if (d.targetKcal > 0 && d.kcal > 1.1 * d.targetKcal) return BarKind.over;
  return BarKind.normal;
}

enum DotKind { none, ok, over, today }

DotKind dotKind(HistoryDay d, String today) {
  if (d.date == today) return DotKind.today;
  if (d.itemCount <= 0 && d.kcal <= 0) return DotKind.none;
  if (inTarget(d)) return DotKind.ok;
  if (d.targetKcal > 0 && d.kcal > 1.1 * d.targetKcal) return DotKind.over;
  return DotKind.none;
}

class MacroAverages {
  const MacroAverages({
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.proteinPct,
    required this.carbsPct,
    required this.fatPct,
  });

  final double proteinG, carbsG, fatG;
  final int proteinPct, carbsPct, fatPct;
}

/// Trung bình macro các ngày được tính; % theo năng lượng (P×4, C×4, F×9).
MacroAverages? macroAverages(List<HistoryDay> days, String today) {
  final counted = days.where((d) => countsForStats(d, today)).toList();
  if (counted.isEmpty) return null;
  final n = counted.length;
  final p = counted.fold<double>(0, (s, d) => s + d.proteinG) / n;
  final c = counted.fold<double>(0, (s, d) => s + d.carbsG) / n;
  final f = counted.fold<double>(0, (s, d) => s + d.fatG) / n;
  final total = p * 4 + c * 4 + f * 9;
  int pct(double kcal) => total <= 0 ? 0 : (kcal / total * 100).round();
  return MacroAverages(
    proteinG: p,
    carbsG: c,
    fatG: f,
    proteinPct: pct(p * 4),
    carbsPct: pct(c * 4),
    fatPct: pct(f * 9),
  );
}

/// Trần trục Y: max(kcal, mục tiêu) làm tròn lên bội 1000, tối thiểu 1000.
double chartMaxY(List<HistoryDay> days) {
  var m = 0.0;
  for (final d in days) {
    m = math.max(m, math.max(d.kcal, d.targetKcal));
  }
  return math.max(1000, (m / 1000).ceil() * 1000).toDouble();
}

/// Chỉ số nhãn trục X: n ≤ 7 thì tất cả; ngược lại neo ở hôm nay, cách 7 ngày.
List<int> xLabelIndexes(int n) {
  if (n <= 7) return [for (var i = 0; i < n; i++) i];
  return [
    for (var i = 0; i < n; i++)
      if ((n - 1 - i) % 7 == 0) i,
  ];
}
