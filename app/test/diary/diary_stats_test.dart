import 'package:elytra/core/edit_window.dart';
import 'package:elytra/core/meal_time.dart';
import 'package:elytra/features/diary/diary_screen.dart';
import 'package:elytra/features/diary/widgets/history_chart.dart';
import 'package:elytra/features/meal_logs/diary_scope.dart';
import 'package:elytra/features/meal_logs/diary_store.dart';
import 'package:elytra/features/meal_logs/meal_log_models.dart';
import 'package:elytra/features/meal_logs/meal_log_repository.dart';
import 'package:elytra/features/recipes/recipe_catalog.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_meal_log_repository.dart';
import '../helpers/fake_recipe_repository.dart';
import '../helpers/meal_log_fixtures.dart';

void main() {
  // 19h giờ VN ngày 11/11/2026 (thứ Tư)
  const today = '2026-11-11';
  late FakeMealLogRepository repo;
  late DiaryStore store;

  /// Lịch sử mẫu: 5/11 2000 · 6/11 2400 (vượt) · 7/11 trống · 8/11 1900 · 9/11 1950 · 10/11 1700.
  History sample(String from, String to) {
    const kcal = {
      '2026-11-05': 2000.0,
      '2026-11-06': 2400.0,
      '2026-11-08': 1900.0,
      '2026-11-09': 1950.0,
      '2026-11-10': 1700.0,
    };
    return History(
      from: from,
      to: to,
      targetKcal: 1968,
      days: [
        for (var d = from; d.compareTo(to) <= 0; d = shiftDate(d, 1))
          hday(d, kcal[d] ?? 0),
      ],
    );
  }

  setUp(() {
    repo = FakeMealLogRepository()..onHistory = sample;
    store = DiaryStore(
      repo: repo,
      now: () => DateTime.utc(2026, 11, 11, 19),
      scheduleMidnight: false,
    );
  });
  tearDown(() => store.dispose());

  Future<void> pumpStats(WidgetTester t, {double width = 390}) async {
    t.view.physicalSize = Size(width, 2400);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    store.requestDiaryView(
      const DiaryViewRequest(segment: DiarySegment.stats, rangeDays: 7),
    );
    final catalog = RecipeCatalog(repo: FakeRecipeRepository());
    addTearDown(catalog.dispose);
    await t.pumpWidget(
      MaterialApp(
        builder: (_, child) => DiaryScope(
          store: store,
          child: RecipeScope(catalog: catalog, child: child!),
        ),
        home: const DiaryScreen(),
      ),
    );
    await t.pumpAndSettle();
  }

  BarChartData chart(WidgetTester t) =>
      t.widget<BarChart>(find.byType(BarChart)).data;

  testWidgets('hai thẻ số: trung bình và số ngày trong mục tiêu', (t) async {
    await pumpStats(t);
    // (2000 + 2400 + 1900 + 1950 + 1700) / 5 = 1990; trong ±10 %: 5/11, 8/11, 9/11
    expect(find.text('1.990'), findsOneWidget);
    expect(find.text('3/5 ngày'), findsOneWidget);
    expect(find.text('Calo mỗi ngày'), findsOneWidget);
    expect(find.text('T5 5/11 – T4 11/11'), findsOneWidget);
  });

  testWidgets('chú giải dùng chữ Không vượt', (t) async {
    await pumpStats(t);
    expect(find.text('Không vượt (≤ 110 %)'), findsOneWidget);
    expect(
      find.text('Trong mục tiêu'),
      findsOneWidget,
    ); // thẻ số, đếm theo ±10 %
    expect(find.text('Hôm nay (đang ghi)'), findsOneWidget);
    expect(find.text('Mục tiêu ngày'), findsOneWidget);
  });

  testWidgets('màu cột theo barKind và trục Y theo chartMaxY', (t) async {
    await pumpStats(t);
    final d = chart(t);
    expect(d.maxY, 3000);
    expect(d.barGroups, hasLength(7));
    expect(
      d.barGroups[1].barRods.single.color,
      const Color(0xFFE11D48),
    ); // 6/11 vượt
    expect(
      d.barGroups[6].barRods.single.color,
      const Color(0xFFBBF7D0),
    ); // hôm nay
  });

  testWidgets('dữ liệu toàn 0 không lỗi trục', (t) async {
    repo.onHistory = (f, to) => History(
      from: f,
      to: to,
      targetKcal: 0,
      days: [
        for (var i = 6; i >= 0; i--)
          hday(shiftDate(to, -i), 0, target: 0, items: 0),
      ],
    );
    await pumpStats(t);
    expect(t.takeException(), isNull);
    expect(find.text('Ghi bữa đầu tiên'), findsOneWidget);
  });

  testWidgets('thống kê khớp Theo ngày khi món đang chờ xoá', (t) async {
    final a = item(id: 'a', name: 'Phở bò', kcal: 300);
    repo.days[today] = dayLog(date: today, items: [(MealType.dinner, a)]);
    await pumpStats(t);
    expect(chart(t).barGroups.last.barRods.single.toY, 300);
    store.deleteDeferred(a, date: today);
    await t.pumpAndSettle();
    expect(chart(t).barGroups.last.barRods.single.toY, 0);
  });

  testWidgets('30 ngày gọi history 30 ngày, nhãn X cách 7 ngày', (t) async {
    await pumpStats(t);
    await t.tap(find.text('30 ngày'));
    await t.pumpAndSettle();
    expect(
      repo.calls.any(
        (c) => c.$1 == 'getHistory' && c.$2 == (shiftDate(today, -29), today),
      ),
      isTrue,
    );
    expect(chart(t).barGroups, hasLength(30));
    expect(find.text('H.nay'), findsOneWidget);
    expect(find.text('4/11'), findsOneWidget);
    expect(find.text('28/10'), findsOneWidget);
    expect(find.text('13/10 – 11/11'), findsOneWidget);
  });

  testWidgets('chạm cột: tooltip; chạm lại thì mở ngày ở Theo ngày', (t) async {
    repo.days['2026-11-06'] = dayLog(
      date: '2026-11-06',
      items: [(MealType.lunch, item(id: 'x', name: 'Lẩu', kcal: 2400))],
    );
    await pumpStats(t);
    final box = t.getRect(find.byType(BarChart));
    // Cột thứ 2 (6/11) trong vùng vẽ: bỏ phần nhãn trục Y bên trái
    final plotLeft = box.left + 40;
    final slot = (box.right - plotLeft) / 7;
    final p = Offset(plotLeft + slot * 1.5, box.bottom - 60);
    await t.tapAt(p);
    await t.pumpAndSettle();
    // Tooltip do fl_chart vẽ trên canvas: kiểm cột đang hiện tooltip
    expect(chart(t).barGroups[1].showingTooltipIndicators, [0]);
    expect(find.text('Calo mỗi ngày'), findsOneWidget); // vẫn ở Thống kê
    await t.tapAt(p);
    await t.pumpAndSettle();
    expect(find.text('T6 · 6/11'), findsOneWidget);
    expect(find.text('Lẩu'), findsOneWidget);
  });

  testWidgets('macro trung bình so với mục tiêu hôm nay', (t) async {
    repo.onHistory = (from, to) => History(
      from: from,
      to: to,
      targetKcal: 1968,
      days: [
        for (var d = from; d.compareTo(to) <= 0; d = shiftDate(d, 1))
          d == '2026-11-10'
              ? const HistoryDay(
                  date: '2026-11-10',
                  kcal: 1900,
                  proteinG: 128,
                  carbsG: 235,
                  fatG: 58,
                  itemCount: 3,
                  targetKcal: 1968,
                )
              : hday(d, 0),
      ],
    );
    repo.days[today] = DayLog(
      date: today,
      budget: const Budget(
        target: Macros(kcal: 1968, proteinG: 130, carbsG: 239, fatG: 55),
        consumed: Macros.zero,
        remaining: Macros(kcal: 1968, proteinG: 130, carbsG: 239, fatG: 55),
      ),
      meals: {for (final m in MealType.values) m: MealLog.empty},
    );
    await pumpStats(t);
    expect(find.text('Macro trung bình mỗi ngày'), findsOneWidget);
    // 128×4 = 512, 235×4 = 940, 58×9 = 522 → tổng 1974
    expect(find.text('Protein · 26 %'), findsOneWidget);
    expect(find.text('Carbs · 48 %'), findsOneWidget);
    expect(find.text('Fat · 26 %'), findsOneWidget);
    expect(find.text('128 g'), findsOneWidget);
    expect(find.text(' / 130 g'), findsOneWidget);
  });

  testWidgets('mất mạng: khối Thử lại', (t) async {
    repo.failOnce['getHistory'] = const MealLogOffline();
    // Lượt tải đầu (dải Theo ngày, 7 ngày) dùng chung khoá với Thống kê 7 ngày
    await pumpStats(t);
    expect(find.text('Thử lại'), findsOneWidget);
    await t.tap(find.text('Thử lại'));
    await t.pumpAndSettle();
    expect(find.byType(BarChart), findsOneWidget);
  });

  testWidgets('chưa có hồ sơ: nút Khai báo thể trạng', (t) async {
    repo.failWith = const MealLogProfileMissing();
    await pumpStats(t);
    expect(find.text('Khai báo thể trạng'), findsOneWidget);
  });

  testWidgets('màn hẹp 320, 30 ngày: không tràn', (t) async {
    await pumpStats(t, width: 320);
    await t.tap(find.text('30 ngày'));
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
  });

  test('nội dung tooltip cột', () {
    expect(historyTooltipLines(hday('2026-11-05', 2240, target: 1968)), (
      'Thứ Năm 5/11',
      '2.240 kcal · vượt 14 %',
    ));
    expect(historyTooltipLines(hday('2026-11-08', 1900, target: 2000)), (
      'Chủ Nhật 8/11',
      '1.900 kcal · 95 % mục tiêu',
    ));
    expect(historyTooltipLines(hday('2026-11-07', 0)), (
      'Thứ Bảy 7/11',
      'Chưa ghi',
    ));
    expect(historyTooltipLines(hday('2026-11-07', 500, target: 0)), (
      'Thứ Bảy 7/11',
      '500 kcal',
    ));
  });
}
