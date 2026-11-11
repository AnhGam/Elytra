import 'package:elytra/features/diary/diary_controller.dart';
import 'package:elytra/features/meal_logs/diary_store.dart';
import 'package:elytra/features/meal_logs/history_stats.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_meal_log_repository.dart';

void main() {
  late FakeMealLogRepository repo;
  late DiaryStore store;
  late DiaryController c;
  var clock = DateTime.utc(2026, 11, 11, 12);
  setUp(() {
    clock = DateTime.utc(2026, 11, 11, 12);
    repo = FakeMealLogRepository();
    store = DiaryStore(repo: repo, now: () => clock, scheduleMidnight: false);
    c = DiaryController(store: store);
  });
  tearDown(() {
    c.dispose();
    store.dispose();
  });

  test('dải mặc định 7 ngày kết thúc hôm nay', () {
    expect(c.stripDates, ['2026-11-05', '2026-11-06', '2026-11-07', '2026-11-08', '2026-11-09', '2026-11-10', '2026-11-11']);
  });
  test('chọn ngày ngoài dải: stripEnd = ngày + 3, không quá hôm nay', () {
    c.selectDate('2026-10-20');
    expect(c.stripEnd, '2026-10-23');
    expect(c.selectedDate, '2026-10-20');
    c.selectDate('2026-11-10'); // ngoài dải
    expect(c.stripEnd, '2026-11-11');
  });
  test('không chọn được ngày tương lai, không lùi dải quá hôm nay', () {
    c.selectDate('2026-11-12');
    expect(c.selectedDate, '2026-11-11');
    c.shiftStrip(1);
    expect(c.stripEnd, '2026-11-11');
    c.shiftStrip(-1);
    expect(c.stripEnd, '2026-11-04');
    expect(c.selectedDate, '2026-11-04');
  });
  test('dải mặc định dùng chung khoá history với Dashboard', () async {
    await pumpEventQueue();
    final r = rangeEnding(store.today, 7);
    expect(repo.calls.where((x) => x.$1 == 'getHistory').map((x) => x.$2), [(r.from, r.to)]);
  });
  test('tải lần đầu hoãn một nhịp (controller thường được tạo trong lúc build)', () async {
    final repo2 = FakeMealLogRepository();
    final store2 = DiaryStore(repo: repo2, now: () => clock, scheduleMidnight: false);
    var notified = 0;
    store2.addListener(() => notified++);
    final c2 = DiaryController(store: store2);
    expect(notified, 0);
    expect(repo2.calls, isEmpty);
    await pumpEventQueue();
    expect(repo2.calls.map((x) => x.$1), containsAll(['getDay', 'getHistory']));
    c2.dispose();
    store2.dispose();
  });
  test('canEdit theo withinEditWindow', () {
    expect(c.canEdit('2026-10-12'), isTrue);
    expect(c.canEdit('2026-10-11'), isFalse);
  });
  test('apply đặt segment, khoảng và ngày; stats tải khoảng thống kê', () async {
    c.apply(const DiaryViewRequest(
        segment: DiarySegment.stats, date: '2026-10-20', rangeDays: 30));
    expect(c.segment, DiarySegment.stats);
    expect(c.rangeDays, 30);
    expect(c.selectedDate, '2026-10-20');
    await pumpEventQueue();
    final r = rangeEnding('2026-11-11', 30);
    expect(repo.calls.where((x) => x.$1 == 'getHistory').map((x) => x.$2),
        contains((r.from, r.to)));
    expect(repo.calls, contains(('getDay', '2026-10-20')));
  });
  test('setRange bỏ qua giá trị khác 7/30', () {
    c.setRange(14);
    expect(c.rangeDays, 7);
    c.setRange(30);
    expect(c.rangeDays, 30);
  });
  test('sang ngày mới: chuyển theo nếu đang ở hôm nay cũ', () {
    clock = DateTime.utc(2026, 11, 12, 1);
    store.checkDayChange();
    expect(c.selectedDate, '2026-11-12');
    expect(c.stripEnd, '2026-11-12');
  });
  test('sang ngày mới: giữ ngày đang xem trong quá khứ', () {
    c.selectDate('2026-11-08');
    clock = DateTime.utc(2026, 11, 12, 1);
    store.checkDayChange();
    expect(c.selectedDate, '2026-11-08');
    expect(c.stripEnd, '2026-11-12'); // dải đang kết thúc ở hôm nay cũ nên theo ngày mới
  });
  test('sang ngày mới: ngày chọn ở đầu dải cũ vẫn nằm trong dải', () {
    c.selectDate('2026-11-05');
    clock = DateTime.utc(2026, 11, 12, 1);
    store.checkDayChange();
    expect(c.stripDates, contains(c.selectedDate));
    expect(c.selectedDate, '2026-11-06');
  });
  test('apply với ngày tương lai vẫn thông báo và tải thống kê', () async {
    var n = 0;
    c.addListener(() => n++);
    c.apply(const DiaryViewRequest(segment: DiarySegment.stats, date: '2026-11-12', rangeDays: 30));
    expect(n, 1);
    expect(c.selectedDate, '2026-11-11');
    await pumpEventQueue();
    final r = rangeEnding('2026-11-11', 30);
    expect(repo.calls.where((x) => x.$1 == 'getHistory').map((x) => x.$2),
        contains((r.from, r.to)));
  });
}
