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
  var clock = DateTime.utc(2026, 11, 11, 12);
  setUp(() {
    clock = DateTime.utc(2026, 11, 11, 12);
    repo = FakeMealLogRepository();
    s = DiaryStore(repo: repo, now: () => clock, scheduleMidnight: false);
  });
  tearDown(() => s.dispose());
  const add1 =
      LogRequest.recipe(refId: 'r1', servings: 1, meal: MealType.lunch, date: '2026-11-11');

  test('ensureDay song song chỉ một request', () async {
    await Future.wait([s.ensureDay('2026-11-11'), s.ensureDay('2026-11-11')]);
    expect(repo.calls.where((c) => c.$1 == 'getDay'), hasLength(1));
  });

  test('add cập nhật ngay cho mọi người nghe; cột hôm nay lấy từ DayLog', () async {
    await s.ensureDay(s.today);
    final r = rangeEnding(s.today, 7);
    await s.ensureHistory(r.from, r.to); // history mặc định: hôm nay 0 kcal
    var a = 0, b = 0;
    s
      ..addListener(() => a++)
      ..addListener(() => b++);
    await s.add(add1, clientRequestId: 'k1');
    expect(a, greaterThan(0));
    expect(b, a);
    expect(s.day(s.today).log!.budget.consumed.kcal, 100);
    expect(s.historyView(r.from, r.to)!.days.last.kcal, 100);
  });

  test('add/delete làm mới mọi khoảng history chứa ngày đó', () async {
    for (final n in [7, 30]) {
      final r = rangeEnding(s.today, n);
      await s.ensureHistory(r.from, r.to);
    }
    repo.calls.clear();
    final res = await s.add(add1, clientRequestId: 'k1');
    await pumpEventQueue();
    expect(repo.calls.where((c) => c.$1 == 'getHistory'), hasLength(2));
    repo.calls.clear();
    await s.delete(res.item, date: s.today);
    await pumpEventQueue();
    expect(repo.calls.where((c) => c.$1 == 'getHistory'), hasLength(2));
  });

  test('store chuyển nguyên khoá cho repo', () async {
    repo.failOnce['add'] = const MealLogOffline();
    await expectLater(s.add(add1, clientRequestId: 'k1'), throwsA(isA<MealLogOffline>()));
    await s.add(add1, clientRequestId: 'k1');
    expect(repo.calls.where((c) => c.$1 == 'add').map((c) => (c.$2 as (LogRequest, String)).$2),
        ['k1', 'k1']);
  });

  test('qua 0h đổi hôm nay', () async {
    await s.ensureDay(s.today);
    clock = DateTime.utc(2026, 11, 12, 0, 1);
    s.checkDayChange();
    expect(s.today, '2026-11-12');
    await pumpEventQueue();
    expect(repo.calls.any((c) => c.$1 == 'getDay' && c.$2 == '2026-11-12'), isTrue);
  });

  test('đổi user: clear và bỏ kết quả về muộn', () async {
    final users = StreamController<String?>();
    final st = DiaryStore(
        repo: repo, userIdChanges: users.stream, now: () => clock, scheduleMidnight: false);
    addTearDown(st.dispose);
    users.add('u1');
    await pumpEventQueue();
    repo.gate = Completer();
    final f = st.ensureDay('2026-11-11');
    users.add('u2');
    await pumpEventQueue();
    repo.gate!.complete();
    await f;
    expect(st.day('2026-11-11').status, LoadStatus.idle);
  });

  test('PROFILE_NOT_FOUND và mất mạng giữ dữ liệu cũ', () async {
    repo.failOnce['getDay'] = const MealLogProfileMissing();
    await s.ensureDay(s.today);
    expect(s.day(s.today).status, LoadStatus.profileMissing);
    await s.refreshDay(s.today);
    repo.failOnce['getDay'] = const MealLogOffline();
    await s.refreshDay(s.today);
    expect(s.day(s.today).status, LoadStatus.offline);
    expect(s.day(s.today).log, isNotNull);
  });

  test('historyView null khi khoảng chưa tải', () {
    final r = rangeEnding(s.today, 7);
    expect(s.historyView(r.from, r.to), isNull);
    expect(s.history(r.from, r.to).status, LoadStatus.idle);
  });

  test('add ghi vào ngày server trả về, không phải ngày app gửi', () async {
    await s.ensureDay('2026-11-11');
    await s.ensureDay('2026-11-12');
    // Gửi ngày 11 nhưng server ghi vào ngày 12 (retry sau 0h)
    repo.addDate = (_) => '2026-11-12';
    final res = await s.add(add1, clientRequestId: 'k2');
    expect(res.item.date, '2026-11-12');
    expect(s.day('2026-11-12').log!.find(res.item.id), isNotNull);
    expect(s.day('2026-11-11').log!.find(res.item.id), isNull);
  });

  test('update thay món trong bữa và làm mới ngày chạy nền', () async {
    final it = item(id: 'a', servings: 1, date: '2026-11-11');
    repo.days['2026-11-11'] = dayLog(items: [(MealType.dinner, it)]);
    await s.ensureDay('2026-11-11');
    repo.calls.clear();
    await s.update(it, servings: 2);
    final log = s.day('2026-11-11').log!;
    expect(log.find('a')!.servings, 2);
    expect(log.mealOf('a'), MealType.dinner);
    await pumpEventQueue();
    expect(repo.calls.where((c) => c.$1 == 'getDay'), hasLength(1));
  });

  test('thao tác lỗi thì ném và không đổi cache', () async {
    final it = item(id: 'a', date: '2026-11-11');
    repo.days['2026-11-11'] = dayLog(items: [(MealType.lunch, it)]);
    await s.ensureDay('2026-11-11');
    repo.failOnce['delete'] = const MealLogTooOld();
    await expectLater(s.delete(it, date: '2026-11-11'), throwsA(isA<MealLogTooOld>()));
    expect(s.day('2026-11-11').log!.find('a'), isNotNull);
  });

  test('lỗi khác ở history thành failed, làm mới nền không ném', () async {
    final r = rangeEnding(s.today, 7);
    await s.ensureHistory(r.from, r.to);
    repo.failOnce['getHistory'] = const MealLogFailed('X');
    await s.add(add1, clientRequestId: 'k1');
    await pumpEventQueue();
    expect(s.history(r.from, r.to).status, LoadStatus.failed);
    expect(s.history(r.from, r.to).history, isNotNull);
  });

  test('add thành công nhưng làm mới nền lỗi: cột hôm nay vẫn khớp DayLog', () async {
    await s.ensureDay(s.today);
    final r = rangeEnding(s.today, 7);
    await s.ensureHistory(r.from, r.to);
    repo.failOnce['getDay'] = const MealLogOffline();
    repo.failOnce['getHistory'] = const MealLogOffline();
    await s.add(add1, clientRequestId: 'k1');
    await pumpEventQueue();
    expect(s.day(s.today).status, LoadStatus.offline);
    final kcal = s.day(s.today).log!.budget.consumed.kcal;
    expect(kcal, 100);
    expect(s.historyView(r.from, r.to)!.days.last.kcal, kcal);
  });

  test('xoá trên ngày offline giữ log cũ: cột hôm nay vẫn khớp DayLog', () async {
    final it = item(id: 'a', date: '2026-11-11');
    repo.days['2026-11-11'] = dayLog(items: [(MealType.lunch, it)]);
    repo.onHistory = (from, to) => History(
          from: from,
          to: to,
          targetKcal: 1968,
          days: [hday(to, 100)],
        );
    await s.ensureDay(s.today);
    final r = rangeEnding(s.today, 7);
    await s.ensureHistory(r.from, r.to);
    repo.failOnce['getDay'] = const MealLogOffline();
    await s.refreshDay(s.today);
    expect(s.day(s.today).status, LoadStatus.offline);
    repo.failOnce['getDay'] = const MealLogOffline();
    repo.failOnce['getHistory'] = const MealLogOffline();
    await s.delete(it, date: s.today);
    await pumpEventQueue();
    final kcal = s.day(s.today).log!.budget.consumed.kcal;
    expect(kcal, 0);
    expect(s.historyView(r.from, r.to)!.days.last.kcal, kcal);
  });

  test('kết quả ghi về sau clear() không vào cache', () async {
    await s.ensureDay(s.today);
    repo.gate = Completer();
    final f = s.add(add1, clientRequestId: 'k1');
    s.clear();
    repo.gate!.complete();
    await f;
    await pumpEventQueue();
    expect(s.day(s.today).status, LoadStatus.idle);
  });
}
