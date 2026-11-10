import 'dart:async';

import 'package:elytra/core/edit_window.dart';
import 'package:elytra/features/meal_logs/meal_log_models.dart';
import 'package:elytra/features/meal_logs/meal_log_repository.dart';

import 'meal_log_fixtures.dart';

/// Bản giả: ghi lại lời gọi (trước khi chờ [gate]), giữ dữ liệu trong [days],
/// có thể ném [failWith] (mọi thao tác) hoặc [failOnce] (một lần theo tên thao tác).
class FakeMealLogRepository implements MealLogRepository {
  /// (op, arg): op là 'getDay'|'getHistory'|'add'|'update'|'delete'.
  final List<(String op, Object arg)> calls = [];
  final Map<String, DayLog> days = {};
  History Function(String from, String to)? onHistory;
  Completer<void>? gate;
  MealLogException? failWith;
  final Map<String, MealLogException> failOnce = {};
  int addCount = 0;

  Future<void> _enter(String op, Object arg) async {
    calls.add((op, arg));
    if (gate != null) await gate!.future;
    final once = failOnce.remove(op);
    if (once != null) throw once;
    if (failWith != null) throw failWith!;
  }

  @override
  Future<DayLog> getDay(String date) async {
    await _enter('getDay', date);
    return days[date] ?? dayLog(date: date);
  }

  @override
  Future<History> getHistory(String from, String to) async {
    await _enter('getHistory', (from, to));
    if (onHistory != null) return onHistory!(from, to);
    final list = <HistoryDay>[];
    for (var d = from; d.compareTo(to) <= 0; d = shiftDate(d, 1)) {
      list.add(hday(d, 0));
    }
    return History(from: from, to: to, targetKcal: 1968, days: list);
  }

  @override
  Future<AddResult> add(LogRequest req, {required String clientRequestId}) async {
    await _enter('add', (req, clientRequestId));
    final n = ++addCount;
    final item = MealLogItem(
      id: 'item-$n',
      source: req.source,
      name: 'Món',
      servings: req.servings,
      amountG: req.amountG?.toDouble(),
      macros: const Macros(kcal: 100),
      mealType: req.meal,
      date: req.date,
    );
    final day = days[req.date] ?? dayLog(date: req.date);
    final budget = day.budget.withConsumed(day.budget.consumed + item.macros);
    days[req.date] = day.upsert(item, req.meal, budget);
    return AddResult(item: item, budget: budget, replayed: false);
  }

  @override
  Future<UpdateResult> updateItem(MealLogItem item,
      {double? servings, int? amountG}) async {
    await _enter('update', (item.id, servings, amountG));
    return UpdateResult(
      item: item.copyWith(servings: servings, amountG: amountG?.toDouble()),
      budget: days[item.date]?.budget ?? dayLog().budget,
    );
  }

  @override
  Future<void> deleteItem(String id) async {
    await _enter('delete', id);
    for (final e in days.entries.toList()) {
      if (e.value.find(id) != null) days[e.key] = e.value.without(id);
    }
  }
}
