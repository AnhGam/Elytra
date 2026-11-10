import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/meal_time.dart';
import 'history_stats.dart';
import 'meal_log_models.dart';
import 'meal_log_repository.dart';

enum LoadStatus { idle, loading, ready, offline, profileMissing, failed }

/// Nhật ký một ngày trong cache; làm mới lỗi thì đổi [status] nhưng giữ [log] cũ.
class DayEntry {
  const DayEntry(this.status, [this.log]);
  final LoadStatus status;
  final DayLog? log;
}

/// Lịch sử một khoảng trong cache; làm mới lỗi thì giữ [history] cũ.
class HistoryEntry {
  const HistoryEntry(this.status, [this.history]);
  final LoadStatus status;
  final History? history;
}

enum DiarySegment { byDay, stats }

/// Yêu cầu mở màn Nhật ký ở một phân đoạn / ngày / khoảng cụ thể.
class DiaryViewRequest {
  const DiaryViewRequest({required this.segment, this.date, this.rangeDays});
  final DiarySegment segment;
  final String? date;
  final int? rangeDays;
}

typedef _Range = (String from, String to);

LoadStatus _statusOf(Object e) => switch (e) {
      MealLogProfileMissing() => LoadStatus.profileMissing,
      MealLogOffline() => LoadStatus.offline,
      _ => LoadStatus.failed,
    };

bool _shouldEnsure(LoadStatus? s) =>
    s == null || s == LoadStatus.idle || s == LoadStatus.offline || s == LoadStatus.failed;

/// Nguồn sự thật duy nhất cho nhật ký: cache DayLog theo ngày và History theo khoảng.
class DiaryStore extends ChangeNotifier {
  DiaryStore({
    required this.repo,
    Stream<String?>? userIdChanges,
    this.now = vnNow,
    this.scheduleMidnight = true,
  }) {
    _today = isoDate(now());
    _sub = userIdChanges?.listen((id) {
      // Lần đầu thấy user (trước đó null) không xoá: tránh huỷ lượt tải đang chạy.
      if (id == null || (_lastUserId != null && id != _lastUserId)) clear();
      _lastUserId = id;
    });
    _armMidnight();
  }

  final MealLogRepository repo;
  /// "Bây giờ" theo giờ VN (tiêm vào để test).
  final DateTime Function() now;

  /// false thì không hẹn Timer 0h (widget test).
  final bool scheduleMidnight;
  StreamSubscription<String?>? _sub;
  String? _lastUserId;
  Timer? _midnight;
  bool _disposed = false;

  late String _today;
  int _generation = 0; // tăng mỗi lần clear để bỏ kết quả tải cũ

  final Map<String, DayEntry> _days = {};
  final Map<String, Future<void>> _dayFlights = {};
  final Map<String, int> _dayTokens = {}; // chỉ lượt tải mới nhất của một ngày được ghi

  final Map<_Range, HistoryEntry> _histories = {};
  final Map<_Range, Future<void>> _historyFlights = {};
  final Map<_Range, int> _historyTokens = {};

  /// Yêu cầu mở màn Nhật ký (vd. từ Dashboard).
  final ValueNotifier<DiaryViewRequest?> viewRequest = ValueNotifier(null);

  String get today => _today;

  // ---------- Đọc ----------

  /// Nhật ký ngày [date]; chưa tải thì `idle`.
  DayEntry day(String date) {
    final e = _days[date];
    if (e == null) return const DayEntry(LoadStatus.idle);
    return DayEntry(e.status, _viewDay(e.log));
  }

  HistoryEntry history(String from, String to) =>
      _histories[(from, to)] ?? const HistoryEntry(LoadStatus.idle);

  /// Lịch sử đã ghép: ngày nào có DayLog trong cache (kể cả hôm nay, kể cả khi làm mới lỗi)
  /// thì lấy số từ DayLog để khớp vòng calo. Khoảng chưa tải thì null.
  History? historyView(String from, String to) {
    final h = _histories[(from, to)]?.history;
    if (h == null) return null;
    return History(
      from: h.from,
      to: h.to,
      targetKcal: h.targetKcal,
      days: [
        for (final d in h.days) _mergeDay(d),
      ],
    );
  }

  HistoryDay _mergeDay(HistoryDay d) {
    final e = _days[d.date];
    // Có log trong cache (kể cả log cũ giữ lại khi làm mới lỗi) thì luôn dùng log
    final log = _viewDay(e?.log);
    if (log == null) return d;
    final c = log.budget.consumed;
    return d.copyWith(
      kcal: c.kcal,
      proteinG: c.proteinG,
      carbsG: c.carbsG,
      fatG: c.fatG,
      itemCount: log.meals.values.fold<int>(0, (s, m) => s + m.items.length),
    );
  }

  // Điểm duy nhất biến DayLog trong cache thành bản hiển thị (Task 8 trừ món chờ xoá ở đây).
  DayLog? _viewDay(DayLog? log) => log;

  // ---------- Tải ----------

  /// Chỉ tải khi `idle`, `offline` hoặc `failed`; gọi trùng dùng chung Future.
  Future<void> ensureDay(String date) {
    final running = _dayFlights[date];
    if (running != null) return running;
    if (!_shouldEnsure(_days[date]?.status)) return Future.value();
    return _loadDay(date);
  }

  /// Tải lại ngày [date]; không ném lỗi (lỗi ghi vào `status`).
  Future<void> refreshDay(String date) => _loadDay(date);

  Future<void> ensureHistory(String from, String to) {
    final key = (from, to);
    final running = _historyFlights[key];
    if (running != null) return running;
    if (!_shouldEnsure(_histories[key]?.status)) return Future.value();
    return _loadHistory(key);
  }

  Future<void> refreshHistory(String from, String to) => _loadHistory((from, to));

  // [force]: luôn gửi request mới (sau thao tác ghi), lượt cũ đang chạy bị bỏ kết quả.
  Future<void> _loadDay(String date, {bool force = false}) {
    final running = _dayFlights[date];
    if (running != null && !force) return running;
    final gen = _generation;
    final token = (_dayTokens[date] ?? 0) + 1;
    _dayTokens[date] = token;
    if (_days[date]?.log == null && _days[date]?.status != LoadStatus.loading) {
      _days[date] = const DayEntry(LoadStatus.loading);
      _notify();
    }
    bool current() => gen == _generation && _dayTokens[date] == token;
    late final Future<void> f;
    f = () async {
      try {
        final log = await repo.getDay(date);
        if (!current()) return;
        _days[date] = DayEntry(LoadStatus.ready, log);
      } catch (e) {
        if (!current()) return;
        _days[date] = DayEntry(_statusOf(e), _days[date]?.log);
      }
      _notify();
    }()
        .whenComplete(() {
      if (identical(_dayFlights[date], f)) _dayFlights.remove(date);
    });
    _dayFlights[date] = f;
    return f;
  }

  Future<void> _loadHistory(_Range key, {bool force = false}) {
    final running = _historyFlights[key];
    if (running != null && !force) return running;
    final gen = _generation;
    final token = (_historyTokens[key] ?? 0) + 1;
    _historyTokens[key] = token;
    if (_histories[key]?.history == null &&
        _histories[key]?.status != LoadStatus.loading) {
      _histories[key] = const HistoryEntry(LoadStatus.loading);
      _notify();
    }
    bool current() => gen == _generation && _historyTokens[key] == token;
    late final Future<void> f;
    f = () async {
      try {
        final h = await repo.getHistory(key.$1, key.$2);
        if (!current()) return;
        _histories[key] = HistoryEntry(LoadStatus.ready, h);
      } catch (e) {
        if (!current()) return;
        _histories[key] = HistoryEntry(_statusOf(e), _histories[key]?.history);
      }
      _notify();
    }()
        .whenComplete(() {
      if (identical(_historyFlights[key], f)) _historyFlights.remove(key);
    });
    _historyFlights[key] = f;
    return f;
  }

  // ---------- Ghi ----------

  /// Ghi món; lỗi thì ném [MealLogException] và không đổi cache.
  /// [clientRequestId] chuyển nguyên vẹn cho repository.
  Future<AddResult> add(LogRequest req, {required String clientRequestId}) async {
    final gen = _generation;
    final r = await repo.add(req, clientRequestId: clientRequestId);
    if (gen == _generation) {
      // Ngày/bữa theo server: retry sau 0h có thể ghi vào ngày khác ngày gửi
      final date = r.item.date ?? req.date;
      _upsert(date, r.item, r.item.mealType ?? req.meal, r.budget);
      _afterMutation(date);
    }
    return r;
  }

  /// Sửa lượng của món; lỗi thì ném và không đổi cache.
  Future<void> update(MealLogItem item, {double? servings, int? amountG}) async {
    final gen = _generation;
    final r = await repo.updateItem(item, servings: servings, amountG: amountG);
    if (gen != _generation) return;
    final date = r.item.date ?? item.date;
    if (date == null) return;
    final meal = r.item.mealType ?? item.mealType ?? _days[date]?.log?.mealOf(item.id);
    if (meal != null) _upsert(date, r.item, meal, r.budget);
    _afterMutation(date);
  }

  /// Xoá món; thành công thì bỏ khỏi cache ngay rồi làm mới chạy nền.
  Future<void> delete(MealLogItem item, {required String date}) async {
    final gen = _generation;
    await repo.deleteItem(item.id);
    if (gen != _generation) return;
    final e = _days[date];
    if (e?.log != null) {
      _days[date] = DayEntry(e!.status, e.log!.without(item.id));
      _notify();
    }
    _afterMutation(date);
  }

  /// Hoàn tác lần ghi vừa rồi (= xoá món đó).
  Future<void> undoAdd(AddResult r) => delete(r.item, date: r.item.date ?? _today);

  void _upsert(String date, MealLogItem item, MealType meal, Budget budget) {
    final log = _days[date]?.log;
    // Ngày chưa có trong cache thì chờ refreshDay chạy nền tải về
    if (log == null) return;
    _days[date] = DayEntry(LoadStatus.ready, log.upsert(item, meal, budget));
    _notify();
  }

  void _afterMutation(String date) {
    unawaited(_loadDay(date, force: true));
    for (final key in _histories.keys.toList()) {
      if (key.$1.compareTo(date) <= 0 && key.$2.compareTo(date) >= 0) {
        unawaited(_loadHistory(key, force: true));
      }
    }
  }

  // ---------- Đổi ngày / người dùng ----------

  /// Gọi khi app quay lại và lúc 0h giờ VN: sang ngày mới thì làm mới hôm nay và 7 ngày qua.
  void checkDayChange() {
    final t = isoDate(now());
    if (t == _today) return;
    _today = t;
    _notify();
    unawaited(refreshDay(t));
    final r = rangeEnding(t, 7);
    unawaited(refreshHistory(r.from, r.to));
  }

  void _armMidnight() {
    if (!scheduleMidnight || _disposed) return;
    final n = now();
    final next = n.isUtc
        ? DateTime.utc(n.year, n.month, n.day + 1)
        : DateTime(n.year, n.month, n.day + 1);
    // Trễ 1 giây cho chắc đã sang ngày mới
    _midnight = Timer(next.difference(n) + const Duration(seconds: 1), () {
      checkDayChange();
      _armMidnight();
    });
  }

  /// Về trạng thái ban đầu (đăng xuất / đổi user); kết quả của request cũ bị bỏ.
  void clear() {
    _generation++;
    _days.clear();
    _dayFlights.clear();
    _dayTokens.clear();
    _histories.clear();
    _historyFlights.clear();
    _historyTokens.clear();
    _today = isoDate(now());
    _notify();
  }

  void requestDiaryView(DiaryViewRequest r) => viewRequest.value = r;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _midnight?.cancel();
    _sub?.cancel();
    viewRequest.dispose();
    super.dispose();
  }
}
