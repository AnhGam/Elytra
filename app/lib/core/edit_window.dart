import 'meal_time.dart';

final _isoRe = RegExp(r'^\d{4}-\d{2}-\d{2}$');

/// Đọc chuỗi `yyyy-MM-dd` thành ngày UTC; sai dạng hoặc ngày không có thật thì null.
DateTime? parseIsoDate(String s) {
  if (!_isoRe.hasMatch(s)) return null;
  final y = int.parse(s.substring(0, 4));
  final m = int.parse(s.substring(5, 7));
  final d = int.parse(s.substring(8, 10));
  final dt = DateTime.utc(y, m, d);
  if (dt.year != y || dt.month != m || dt.day != d) return null;
  return dt;
}

/// Cộng/trừ [days] ngày trên chuỗi ngày [iso]. Sai dạng thì ném ArgumentError.
String shiftDate(String iso, int days) {
  final dt = parseIsoDate(iso);
  if (dt == null) throw ArgumentError.value(iso, 'iso', 'Ngày sai dạng');
  return isoDate(dt.add(Duration(days: days)));
}

/// Còn trong cửa sổ sửa: `today - 30 ngày <= date <= today`. Sai dạng thì false.
bool withinEditWindow(String date, String today) {
  if (parseIsoDate(date) == null || parseIsoDate(today) == null) return false;
  // Chuỗi yyyy-MM-dd so sánh từ điển đúng thứ tự thời gian.
  return date.compareTo(shiftDate(today, -30)) >= 0 && date.compareTo(today) <= 0;
}
