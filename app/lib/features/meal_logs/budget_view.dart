import 'package:intl/intl.dart';

import 'meal_log_models.dart';

final _kcalFmt = NumberFormat('#,##0', 'vi');
final _gramFmt = NumberFormat('#,##0.#', 'vi');

/// Số nguyên kiểu VN: `1.968`.
String formatKcal(num v) => _kcalFmt.format(v.round());

/// Một chữ số thập phân, bỏ `,0`: `58,5`, `130`.
String formatGram(num v) => _gramFmt.format(v);

/// Tỉ lệ đã nạp/mục tiêu, kẹp 0–1; không có mục tiêu thì 0.
double progressRatio(double consumed, double? target) {
  if (target == null || target <= 0) return 0;
  return (consumed / target).clamp(0.0, 1.0);
}

bool isOver(double consumed, double? target) =>
    target != null && target > 0 && consumed > target;

/// Phần trăm vượt mục tiêu (làm tròn).
int overPct(double consumed, double target) {
  if (target <= 0) return 0;
  return ((consumed / target - 1) * 100).round();
}

/// `Còn 61,6 g` hoặc `Vượt 12 g` khi âm.
String gramRemainingLabel(double remaining) => remaining < 0
    ? 'Vượt ${formatGram(-remaining)} g'
    : 'Còn ${formatGram(remaining)} g';

/// Số và chú thích ở tâm vòng kcal.
({String value, String caption}) ringCenter(Budget b) {
  final left = b.remaining.kcal;
  return left < 0
      ? (value: formatKcal(-left), caption: 'kcal vượt mức')
      : (value: formatKcal(left), caption: 'kcal còn lại');
}
