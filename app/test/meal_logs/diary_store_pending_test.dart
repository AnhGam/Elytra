import 'dart:async';

import 'package:elytra/core/meal_time.dart';
import 'package:elytra/features/meal_logs/diary_store.dart';
import 'package:elytra/features/meal_logs/history_stats.dart';
import 'package:elytra/features/meal_logs/meal_log_models.dart';
import 'package:elytra/features/meal_logs/meal_log_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_meal_log_repository.dart';
import '../helpers/meal_log_fixtures.dart';

void main() {
  late FakeMealLogRepository repo;
  late DiaryStore s;
  setUp(() {
    repo = FakeMealLogRepository();
    s = DiaryStore(
      repo: repo,
      now: () => DateTime.utc(2026, 11, 11, 12),
      scheduleMidnight: false,
    );
  });
  tearDown(() => s.dispose());

  test('treo: ẩn ở mọi view; undo trả lại, không request', () async {
    final it = item(id: 'a', kcal: 300, date: s.today);
    repo.days[s.today] = dayLog(date: s.today, items: [(MealType.lunch, it)]);
    final r = rangeEnding(s.today, 7);
    await s.ensureDay(s.today); await s.ensureHistory(r.from, r.to);
    final p = s.deleteDeferred(it, date: s.today);
    expect(s.day(s.today).log!.find('a'), isNull);
    expect(s.historyView(r.from, r.to)!.days.last.kcal, 0);
    p.undo();
    expect(s.day(s.today).log!.find('a'), isNotNull);
    expect(s.historyView(r.from, r.to)!.days.last.kcal, 300);
    expect(repo.calls.where((c) => c.$1 == 'delete'), isEmpty);
  });
  test('ngày cũ chỉ có trong /history cũng bị trừ', () async {
    repo.onHistory = (f, t) => History(from: f, to: t, targetKcal: 1968, days: [hday(f, 500, items: 2)]);
    await s.ensureHistory('2026-11-05', '2026-11-05');
    s.deleteDeferred(item(id: 'b', kcal: 200), date: '2026-11-05');
    final d = s.historyView('2026-11-05', '2026-11-05')!.days.single;
    expect(d.kcal, 300); expect(d.itemCount, 1);
  });
  test('commit gửi DELETE; lỗi thì món hiện lại', () async {
    final it = item(id: 'a'); repo.days[s.today] = dayLog(date: s.today, items: [(MealType.lunch, it)]);
    await s.ensureDay(s.today);
    repo.failOnce['delete'] = const MealLogOffline();
    await expectLater(s.deleteDeferred(it, date: s.today).commit(), throwsA(isA<MealLogOffline>()));
    expect(s.day(s.today).log!.find('a'), isNotNull);
  });
  test('vuốt món thứ hai thì món đầu được commit', () async {
    s.deleteDeferred(item(id: 'a'), date: s.today);
    s.deleteDeferred(item(id: 'b'), date: s.today);
    await pumpEventQueue();
    expect(repo.calls.where((c) => c.$1 == 'delete').map((c) => c.$2), ['a']);
  });
  test('flush gửi hết; clear chỉ bỏ', () async {
    s.deleteDeferred(item(id: 'a'), date: s.today);
    await s.flushPendingDeletes();
    expect(repo.calls.where((c) => c.$1 == 'delete'), hasLength(1));
    s.deleteDeferred(item(id: 'b'), date: s.today);
    s.clear();
    await pumpEventQueue();
    expect(repo.calls.where((c) => c.$1 == 'delete'), hasLength(1));
  });

  // ---- Bổ sung: các trường hợp biên theo Ruling R8 ----

  test('commit hai lần chỉ gửi một DELETE; undo sau commit không làm gì', () async {
    final it = item(id: 'a', kcal: 300);
    repo.days[s.today] = dayLog(date: s.today, items: [(MealType.lunch, it)]);
    await s.ensureDay(s.today);
    final p = s.deleteDeferred(it, date: s.today);
    final f1 = p.commit();
    final f2 = p.commit();
    expect(identical(f1, f2), isTrue);
    p.undo();
    expect(s.day(s.today).log!.find('a'), isNull);
    await f1;
    expect(repo.calls.where((c) => c.$1 == 'delete'), hasLength(1));
    expect(s.day(s.today).log!.find('a'), isNull);
  });

  test('tự commit món trước bị lỗi thì món đó hiện lại, không lỗi treo', () async {
    final a = item(id: 'a'), b = item(id: 'b');
    repo.days[s.today] = dayLog(date: s.today, items: [(MealType.lunch, a), (MealType.lunch, b)]);
    await s.ensureDay(s.today);
    repo.failOnce['delete'] = const MealLogOffline();
    s.deleteDeferred(a, date: s.today);
    s.deleteDeferred(b, date: s.today);
    await pumpEventQueue();
    expect(s.day(s.today).log!.find('a'), isNotNull);
    expect(s.day(s.today).log!.find('b'), isNull);
  });

  test('commit sau clear không gửi DELETE', () async {
    final p = s.deleteDeferred(item(id: 'a'), date: s.today);
    s.clear();
    await p.commit();
    expect(repo.calls.where((c) => c.$1 == 'delete'), isEmpty);
  });

  test('ngày chỉ có trong /history: commit xong vẫn ẩn, không nhảy lại số cũ', () async {
    final b = item(id: 'b', kcal: 200);
    // Server có đủ hai món; làm mới sau DELETE sẽ tải cả DayLog của ngày đó
    repo.days['2026-11-05'] = dayLog(
        date: '2026-11-05', items: [(MealType.lunch, item(id: 'a', kcal: 300)), (MealType.dinner, b)]);
    var deleted = false;
    repo.onHistory = (f, t) => History(
        from: f, to: t, targetKcal: 1968,
        days: [deleted ? hday(f, 300, items: 1) : hday(f, 500, items: 2)]);
    await s.ensureHistory('2026-11-05', '2026-11-05');
    final p = s.deleteDeferred(b, date: '2026-11-05');
    final c = p.commit();
    deleted = true;
    await c;
    expect(s.historyView('2026-11-05', '2026-11-05')!.days.single.kcal, 300);
    await pumpEventQueue();
    final d = s.historyView('2026-11-05', '2026-11-05')!.days.single;
    expect(d.kcal, 300);
    expect(d.itemCount, 1);
  });

  test('trừ ở /history không xuống dưới 0', () async {
    repo.onHistory = (f, t) => History(from: f, to: t, targetKcal: 1968, days: [hday(f, 100, items: 1)]);
    await s.ensureHistory('2026-11-05', '2026-11-05');
    s.deleteDeferred(item(id: 'x', kcal: 300), date: '2026-11-05');
    s.deleteDeferred(item(id: 'y', kcal: 300), date: '2026-11-05');
    final d = s.historyView('2026-11-05', '2026-11-05')!.days.single;
    expect(d.kcal, greaterThanOrEqualTo(0));
    expect(d.itemCount, greaterThanOrEqualTo(0));
  });

  group('ngày chỉ có trong /history: không trừ hai lần', () {
    const d = '2026-11-05';
    const range = ('2026-11-05', '2026-11-05');
    final a = item(id: 'a', kcal: 300);
    late double serverKcal; // số server trả cho ngày d
    late int serverItems;

    setUp(() {
      serverKcal = 500; // a 300 + b 200
      serverItems = 2;
      repo.onHistory = (f, t) => History(
            from: f,
            to: t,
            targetKcal: 1968,
            days: [hday(d, serverKcal, items: serverItems)],
          );
      // Nhật ký ngày trên "server": DELETE của repo giả bỏ a khỏi đây
      repo.days[d] = dayLog(date: d, items: [
        (MealType.lunch, a),
        (MealType.lunch, item(id: 'b', kcal: 200)),
      ]);
    });

    double viewKcal() => s.historyView(range.$1, range.$2)!.days.single.kcal;

    test('history làm mới về giữa lúc DELETE đang bay (server đã xoá)', () async {
      await s.ensureHistory(range.$1, range.$2);
      final p = s.deleteDeferred(a, date: d);
      expect(viewKcal(), 200);
      repo.deleteGate = Completer();
      final commit = p.commit();
      // Server đã xoá a; một lượt làm mới khác (vd. do thao tác khác) về trước khi DELETE trả lời
      serverKcal = 200;
      serverItems = 1;
      await s.refreshHistory(range.$1, range.$2);
      expect(viewKcal(), 200);
      repo.deleteGate!.complete();
      await commit;
      // Ngay khi DELETE xong (lượt làm mới sau DELETE chưa về) vẫn đúng
      expect(viewKcal(), 200);
      await pumpEventQueue();
      expect(viewKcal(), 200);
      expect(s.historyView(range.$1, range.$2)!.days.single.itemCount, 1);
    });

    test('commit trước khi lượt làm mới về: số không âm và khớp Theo ngày', () async {
      await s.ensureHistory(range.$1, range.$2);
      final p = s.deleteDeferred(a, date: d);
      repo.deleteGate = Completer();
      final commit = p.commit();
      serverKcal = 200;
      serverItems = 1;
      repo.deleteGate!.complete();
      await commit;
      expect(viewKcal(), 200);
      await pumpEventQueue();
      expect(viewKcal(), 200);
      // Mở ngày đó ở Theo ngày: cùng số
      await s.ensureDay(d);
      expect(s.day(d).log!.budget.consumed.kcal, 200);
      expect(viewKcal(), 200);
    });

    test('history lấy trước khi gửi DELETE vẫn được trừ đúng một lần', () async {
      await s.ensureHistory(range.$1, range.$2);
      final p = s.deleteDeferred(a, date: d);
      // Server chậm: lượt làm mới sau DELETE chưa về thì vẫn hiện 200
      repo.gate = null;
      await p.commit();
      expect(viewKcal(), 200);
    });
  });
}
