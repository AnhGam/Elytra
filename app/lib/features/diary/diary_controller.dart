import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/edit_window.dart';
import '../meal_logs/diary_store.dart';
import '../meal_logs/history_stats.dart';

/// Trạng thái xem của tab Nhật ký: phân đoạn, ngày đang chọn, dải 7 ngày, khoảng thống kê.
/// Dữ liệu tải qua [DiaryStore].
class DiaryController extends ChangeNotifier {
  DiaryController({required this.store}) {
    _lastToday = store.today;
    selectedDate = stripEnd = store.today;
    store.addListener(_onStore);
    _load();
  }

  final DiaryStore store;

  DiarySegment segment = DiarySegment.byDay;
  late String selectedDate;
  late String stripEnd;
  int rangeDays = 7;

  late String _lastToday;
  bool _disposed = false;

  /// 7 ngày tăng dần, kết thúc ở [stripEnd].
  List<String> get stripDates =>
      [for (var i = 6; i >= 0; i--) shiftDate(stripEnd, -i)];

  ({String from, String to}) get statsRange => rangeEnding(store.today, rangeDays);

  bool canEdit(String date) => withinEditWindow(date, store.today);

  void selectDate(String d) {
    if (_setDate(d)) _changed();
  }

  // Đặt ngày (và dời dải nếu cần) mà không thông báo; false nếu bỏ qua ngày tương lai.
  bool _setDate(String d) {
    if (d.compareTo(store.today) > 0) return false;
    if (!stripDates.contains(d)) {
      final e = shiftDate(d, 3);
      stripEnd = e.compareTo(store.today) < 0 ? e : store.today;
    }
    selectedDate = d;
    return true;
  }

  /// [direction] -1 lùi một dải (7 ngày), +1 tiến; không vượt hôm nay.
  void shiftStrip(int direction) {
    final e = shiftDate(stripEnd, 7 * direction);
    stripEnd = e.compareTo(store.today) > 0 ? store.today : e;
    if (!stripDates.contains(selectedDate)) selectedDate = stripEnd;
    _changed();
  }

  void setSegment(DiarySegment s) {
    segment = s;
    _changed();
  }

  void setRange(int days) {
    if (days != 7 && days != 30) return;
    rangeDays = days;
    _changed();
  }

  void apply(DiaryViewRequest r) {
    segment = r.segment;
    final days = r.rangeDays;
    if (days != null && (days == 7 || days == 30)) rangeDays = days;
    final d = r.date;
    if (d != null) _setDate(d);
    _changed();
  }

  // Sang ngày mới: view đang ở hôm nay cũ thì chuyển theo.
  void _onStore() {
    final t = store.today;
    if (t == _lastToday) return;
    final old = _lastToday;
    _lastToday = t;
    if (selectedDate == old) selectedDate = t;
    if (stripEnd == old) stripEnd = t;
    // Dải dời tới thì ngày quá khứ có thể rơi ra ngoài: kẹp về đầu dải
    if (selectedDate.compareTo(stripDates.first) < 0) selectedDate = stripDates.first;
    _changed();
  }

  void _changed() {
    if (_disposed) return;
    notifyListeners();
    _load();
  }

  void _load() {
    unawaited(store.ensureDay(selectedDate));
    unawaited(store.ensureHistory(stripDates.first, stripEnd));
    if (segment == DiarySegment.stats) {
      final r = statsRange;
      unawaited(store.ensureHistory(r.from, r.to));
    }
  }

  @override
  void dispose() {
    _disposed = true;
    store.removeListener(_onStore);
    super.dispose();
  }
}
