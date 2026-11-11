import 'dart:async';

import 'package:elytra/core/edit_window.dart';
import 'package:elytra/core/meal_time.dart';
import 'package:elytra/features/diary/diary_screen.dart';
import 'package:elytra/features/meal_logs/diary_scope.dart';
import 'package:elytra/features/meal_logs/diary_store.dart';
import 'package:elytra/features/meal_logs/meal_log_models.dart';
import 'package:elytra/features/meal_logs/meal_log_repository.dart';
import 'package:elytra/features/recipes/recipe_catalog.dart';
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

  setUp(() {
    repo = FakeMealLogRepository();
    store = DiaryStore(
      repo: repo,
      now: () => DateTime.utc(2026, 11, 11, 19),
      scheduleMidnight: false,
    );
  });
  tearDown(() => store.dispose());

  Future<void> pumpDiary(
    WidgetTester t, {
    DiaryViewRequest? request,
    double width = 390,
  }) async {
    t.view.physicalSize = Size(width, 2400);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    if (request != null) store.requestDiaryView(request);
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

  List<(String, Object)> callsOf(String op) => [
    for (final c in repo.calls)
      if (c.$1 == op) c,
  ];

  void lunch(String date, List<MealLogItem> items) {
    repo.days[date] = dayLog(
      date: date,
      items: [for (final i in items) (MealType.lunch, i)],
    );
  }

  testWidgets('dải 7 ngày kết thúc hôm nay, thẻ tóm tắt ngày', (t) async {
    lunch(today, [item(id: 'a', name: 'Cơm trắng', kcal: 260)]);
    await pumpDiary(t);
    expect(find.text('H.nay'), findsOneWidget);
    for (final d in ['5', '6', '7', '8', '9', '10', '11']) {
      expect(find.text(d), findsOneWidget);
    }
    expect(find.text('Hôm nay · 11/11'), findsOneWidget);
    expect(find.text('260 / 1.968 kcal'), findsOneWidget);
    expect(find.text('Cơm trắng'), findsOneWidget);
    expect(find.text('1 phần'), findsOneWidget);
  });

  testWidgets('chạm ô ngày khác thì xem ngày đó', (t) async {
    lunch('2026-11-09', [item(id: 'b', name: 'Bún chả')]);
    await pumpDiary(t);
    await t.tap(find.text('9'));
    await t.pumpAndSettle();
    expect(find.text('T2 · 9/11'), findsOneWidget);
    expect(find.text('Bún chả'), findsOneWidget);
  });

  testWidgets('xoá món cuối của bữa → bữa trống', (t) async {
    lunch(today, [item(id: 'a', name: 'Cơm trắng')]);
    await pumpDiary(t);
    await t.drag(find.text('Cơm trắng'), const Offset(-500, 0));
    await t.pumpAndSettle();
    expect(find.text('Chưa ghi món nào'), findsNWidgets(4));
    expect(find.text('Đã xoá Cơm trắng'), findsOneWidget);
  });

  testWidgets('vuốt xoá rồi Hoàn tác: không gửi DELETE', (t) async {
    lunch(today, [item(id: 'a', name: 'Cơm trắng')]);
    await pumpDiary(t);
    await t.drag(find.text('Cơm trắng'), const Offset(-500, 0));
    await t.pumpAndSettle();
    await t.tap(find.text('Hoàn tác'));
    await t.pumpAndSettle();
    expect(find.text('Cơm trắng'), findsOneWidget);
    await t.pump(const Duration(seconds: 5));
    await t.pumpAndSettle();
    expect(callsOf('delete'), isEmpty);
  });

  testWidgets('vuốt xoá, snackbar hết giờ thì gửi DELETE', (t) async {
    lunch(today, [item(id: 'a', name: 'Cơm trắng')]);
    await pumpDiary(t);
    await t.drag(find.text('Cơm trắng'), const Offset(-500, 0));
    await t.pumpAndSettle();
    expect(callsOf('delete'), isEmpty);
    await t.pump(const Duration(seconds: 5));
    await t.pumpAndSettle();
    expect(callsOf('delete').map((c) => c.$2), ['a']);
  });

  testWidgets('DELETE lỗi: món hiện lại và báo lỗi', (t) async {
    lunch(today, [item(id: 'a', name: 'Cơm trắng')]);
    repo.failOnce['delete'] = const MealLogOffline();
    await pumpDiary(t);
    await t.drag(find.text('Cơm trắng'), const Offset(-500, 0));
    await t.pumpAndSettle();
    await t.pump(const Duration(seconds: 5));
    await t.pumpAndSettle();
    expect(find.text('Cơm trắng'), findsOneWidget);
    expect(find.text('Không xoá được. Thử lại'), findsOneWidget);
  });

  testWidgets('rời màn khi món đang chờ xoá thì gửi DELETE', (t) async {
    lunch(today, [item(id: 'a', name: 'Cơm trắng')]);
    await pumpDiary(t);
    await t.drag(find.text('Cơm trắng'), const Offset(-500, 0));
    await t.pumpAndSettle();
    await t.pumpWidget(const SizedBox());
    await t.pumpAndSettle();
    expect(callsOf('delete').map((c) => c.$2), ['a']);
  });

  testWidgets('món ngày thứ 31 bị khoá', (t) async {
    final old = shiftDate(today, -31);
    lunch(old, [item(id: 'a', name: 'Cơm trắng')]);
    await pumpDiary(
      t,
      request: DiaryViewRequest(segment: DiarySegment.byDay, date: old),
    );
    await t.tap(find.text('Cơm trắng'));
    await t.pumpAndSettle();
    expect(find.text('Lưu thay đổi'), findsNothing);
    expect(
      find.text('Chỉ sửa được món trong 30 ngày gần nhất'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.add), findsNothing);
    await t.drag(find.text('Cơm trắng'), const Offset(-500, 0));
    await t.pumpAndSettle();
    expect(find.text('Cơm trắng'), findsOneWidget);
  });

  testWidgets('món ngày thứ 30 vẫn sửa được', (t) async {
    final d = shiftDate(today, -30);
    lunch(d, [item(id: 'a', name: 'Cơm trắng')]);
    await pumpDiary(
      t,
      request: DiaryViewRequest(segment: DiarySegment.byDay, date: d),
    );
    await t.tap(find.text('Cơm trắng'));
    await t.pumpAndSettle();
    expect(find.text('Lưu thay đổi'), findsOneWidget);
  });

  testWidgets('sửa lượng gửi PATCH', (t) async {
    lunch(today, [item(id: 'a', name: 'Cá basa kho tộ', kcal: 240)]);
    await pumpDiary(t);
    await t.tap(find.text('Cá basa kho tộ'));
    await t.pumpAndSettle();
    expect(find.text('Bữa trưa · Hôm nay · đang ghi 1 phần'), findsOneWidget);
    await t.tap(find.byTooltip('Thêm phần'));
    await t.pump();
    // 1,25 phần × 240 = 300 kcal; cả ngày còn 1968 − 240 − (300 − 240) = 1.668
    expect(find.text('300'), findsOneWidget);
    expect(find.text('Sau khi lưu: cả ngày còn 1.668 kcal'), findsOneWidget);
    await t.tap(find.text('Lưu thay đổi'));
    await t.pumpAndSettle();
    expect(callsOf('update').map((c) => c.$2), [('a', 1.25, null)]);
    expect(find.text('Lưu thay đổi'), findsNothing);
  });

  testWidgets('món theo gam: sheet có ô gam, gửi amount_g', (t) async {
    lunch(today, [
      item(
        id: 'g',
        name: 'Phở bò',
        source: LogSource.dish,
        amountG: 400,
        kcal: 440,
      ),
    ]);
    await pumpDiary(t);
    expect(find.text('400 g'), findsOneWidget);
    await t.tap(find.text('Phở bò'));
    await t.pumpAndSettle();
    await t.enterText(find.byType(TextField), '500');
    await t.pump();
    expect(find.text('550'), findsOneWidget);
    await t.tap(find.text('Lưu thay đổi'));
    await t.pumpAndSettle();
    expect(callsOf('update').map((c) => c.$2), [('g', null, 500)]);
  });

  testWidgets('nút Xoá trong sheet xoá luôn', (t) async {
    lunch(today, [item(id: 'a', name: 'Cơm trắng')]);
    await pumpDiary(t);
    await t.tap(find.text('Cơm trắng'));
    await t.pumpAndSettle();
    await t.tap(find.text('Xoá'));
    await t.pumpAndSettle();
    expect(callsOf('delete').map((c) => c.$2), ['a']);
    expect(find.text('Cơm trắng'), findsNothing);
  });

  testWidgets('server báo món quá 30 ngày khi lưu: hiện ghi chú', (t) async {
    lunch(today, [item(id: 'a', name: 'Cơm trắng')]);
    repo.failOnce['update'] = const MealLogTooOld();
    await pumpDiary(t);
    await t.tap(find.text('Cơm trắng'));
    await t.pumpAndSettle();
    await t.tap(find.byTooltip('Thêm phần'));
    await t.pump();
    await t.tap(find.text('Lưu thay đổi'));
    await t.pumpAndSettle();
    expect(
      find.text('Chỉ sửa được món trong 30 ngày gần nhất'),
      findsOneWidget,
    );
  });

  testWidgets('đang lưu: nút khoá, bấm lặp không gửi thêm', (t) async {
    lunch(today, [item(id: 'a', name: 'Cơm trắng')]);
    await pumpDiary(t);
    await t.tap(find.text('Cơm trắng'));
    await t.pumpAndSettle();
    await t.tap(find.byTooltip('Thêm phần'));
    await t.pump();
    repo.gate = Completer();
    await t.tap(find.text('Lưu thay đổi'));
    await t.pump();
    expect(find.text('Đang lưu…'), findsOneWidget);
    await t.tap(find.text('Đang lưu…'), warnIfMissed: false);
    await t.pump();
    expect(callsOf('update'), hasLength(1));
    repo.gate!.complete();
    await t.pumpAndSettle();
  });

  testWidgets('mất mạng lần đầu: khối Thử lại', (t) async {
    repo.failWith = const MealLogOffline();
    await pumpDiary(t);
    expect(find.text('Thử lại'), findsOneWidget);
    repo.failWith = null;
    await t.tap(find.text('Thử lại'));
    await t.pumpAndSettle();
    expect(find.text('Chưa ghi món nào'), findsNWidgets(4));
  });

  testWidgets('chưa có hồ sơ: nút Khai báo thể trạng', (t) async {
    repo.failWith = const MealLogProfileMissing();
    await pumpDiary(t);
    expect(find.text('Khai báo thể trạng'), findsOneWidget);
  });

  testWidgets('ngày chưa ghi: tóm tắt 0 kcal và 4 bữa trống', (t) async {
    await pumpDiary(t);
    expect(find.text('0 / 1.968 kcal'), findsOneWidget);
    expect(find.text('Chưa ghi món nào'), findsNWidgets(4));
    expect(
      find.text('Chạm món để sửa lượng hoặc xoá · vuốt trái để xoá nhanh'),
      findsOneWidget,
    );
  });

  testWidgets('chấm dưới ô ngày theo history', (t) async {
    repo.onHistory = (from, to) => History(
      from: from,
      to: to,
      targetKcal: 1968,
      days: [
        for (var d = from; d.compareTo(to) <= 0; d = shiftDate(d, 1))
          hday(d, d == '2026-11-06' ? 2400 : (d == '2026-11-07' ? 1968 : 0)),
      ],
    );
    await pumpDiary(t);
    expect(find.byKey(const ValueKey('dot-2026-11-06-over')), findsOneWidget);
    expect(find.byKey(const ValueKey('dot-2026-11-07-ok')), findsOneWidget);
    expect(find.byKey(const ValueKey('dot-2026-11-08-none')), findsOneWidget);
  });

  testWidgets('vuốt dải sang phải thì lùi 7 ngày', (t) async {
    await pumpDiary(t);
    await t.drag(find.text('H.nay'), const Offset(300, 0));
    await t.pumpAndSettle();
    expect(find.text('H.nay'), findsNothing);
    expect(find.text('4'), findsOneWidget); // 29/10 … 4/11
    expect(find.text('29'), findsOneWidget);
  });

  testWidgets('màn hẹp 320: dải ngày và món không tràn', (t) async {
    lunch(today, [
      item(
        id: 'g',
        name: 'Cơm tấm sườn bì chả trứng',
        source: LogSource.dish,
        amountG: 1250,
        kcal: 1234,
      ),
    ]);
    await pumpDiary(t, width: 320);
    expect(t.takeException(), isNull);
    expect(find.text('H.nay'), findsOneWidget);
  });

  for (final err in const <MealLogException>[
    MealLogFailed('X'),
    MealLogOffline(),
  ]) {
    testWidgets('Xoá trong sheet lỗi (${err.runtimeType}): câu riêng cho xoá', (
      t,
    ) async {
      lunch(today, [item(id: 'a', name: 'Cơm trắng')]);
      repo.failOnce['delete'] = err;
      await pumpDiary(t);
      await t.tap(find.text('Cơm trắng'));
      await t.pumpAndSettle();
      await t.tap(find.text('Xoá'));
      await t.pumpAndSettle();
      expect(find.text('Không xoá được. Thử lại'), findsOneWidget);
      expect(find.textContaining('Không lưu được'), findsNothing);
      expect(find.text('Lưu thay đổi'), findsOneWidget); // sheet vẫn mở
    });
  }

  testWidgets('sheet sửa món mở trên root navigator (che thanh tab)', (
    t,
  ) async {
    lunch(today, [item(id: 'a', name: 'Cơm trắng')]);
    final rootKey = GlobalKey<NavigatorState>();
    final catalog = RecipeCatalog(repo: FakeRecipeRepository());
    addTearDown(catalog.dispose);
    t.view.physicalSize = const Size(390, 2400);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    // Giống StatefulShellRoute: màn nằm trong navigator con, thanh tab ở ngoài
    await t.pumpWidget(
      MaterialApp(
        navigatorKey: rootKey,
        builder: (_, child) => DiaryScope(
          store: store,
          child: RecipeScope(catalog: catalog, child: child!),
        ),
        home: Scaffold(
          body: Navigator(
            onGenerateRoute: (_) =>
                MaterialPageRoute(builder: (_) => const DiaryScreen()),
          ),
          bottomNavigationBar: const SizedBox(
            height: 80,
            child: Text('THANH TAB'),
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
    await t.tap(find.text('Cơm trắng'));
    await t.pumpAndSettle();
    final nav = t.state<NavigatorState>(
      find
          .ancestor(
            of: find.text('Lưu thay đổi'),
            matching: find.byType(Navigator),
          )
          .first,
    );
    expect(nav, same(rootKey.currentState));
  });

  testWidgets('segmented Theo ngày | Thống kê: vùng chạm cao ≥ 48', (t) async {
    await pumpDiary(t);
    for (final label in ['Theo ngày', 'Thống kê']) {
      final target = find
          .ancestor(
            of: find.text(label),
            matching: find.byType(GestureDetector),
          )
          .first;
      expect(t.getSize(target).height, greaterThanOrEqualTo(48));
    }
    // Chạm sát mép dưới vùng chạm (ngoài khối 40 nhìn thấy) vẫn chuyển phân đoạn
    final r = t.getRect(
      find
          .ancestor(
            of: find.text('Thống kê'),
            matching: find.byType(GestureDetector),
          )
          .first,
    );
    await t.tapAt(Offset(r.center.dx, r.bottom - 2));
    await t.pumpAndSettle();
    expect(
      find.text('Calo mỗi ngày').evaluate().isNotEmpty ||
          find.text('Ghi bữa đầu tiên').evaluate().isNotEmpty,
      isTrue,
    );
  });
}
