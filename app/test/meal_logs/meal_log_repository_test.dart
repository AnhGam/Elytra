import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:elytra/features/meal_logs/meal_log_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('mất mạng', () {
    expect(mapMealLogError(const FunctionsFetchException(details: 'x')),
        isA<MealLogOffline>());
    expect(mapMealLogError(const SocketException('x')), isA<MealLogOffline>());
    expect(mapMealLogError(TimeoutException('x')), isA<MealLogOffline>());
  });
  test('PROFILE_NOT_FOUND từ details Map hoặc chuỗi JSON', () {
    const map = {
      'error': {'code': 'PROFILE_NOT_FOUND', 'message': 'Chưa có mục tiêu'}
    };
    expect(mapMealLogError(const FunctionException(status: 404, details: map)),
        isA<MealLogProfileMissing>());
    expect(
        mapMealLogError(
            FunctionException(status: 404, details: jsonEncode(map))),
        isA<MealLogProfileMissing>());
  });
  test('lỗi khác giữ code', () {
    final e = mapMealLogError(const FunctionException(
        status: 404, details: {'error': {'code': 'RECIPE_NOT_FOUND'}}));
    expect((e as MealLogFailed).code, 'RECIPE_NOT_FOUND');
    expect(mapMealLogError(StateError('?')), isA<MealLogFailed>());
  });
  test('code/message sai kiểu hoặc body lạ → MealLogFailed, không ném TypeError', () {
    final e = mapMealLogError(const FunctionException(
        status: 500, details: {'error': {'code': 42, 'message': ['x']}}));
    expect(e, isA<MealLogFailed>());
    expect((e as MealLogFailed).code, isNull);
    expect(mapMealLogError(const FunctionException(status: 502, details: '<html>')),
        isA<MealLogFailed>());
    expect(mapMealLogError(const FunctionException(status: 500, details: {'error': 'x'})),
        isA<MealLogFailed>());
  });

  FunctionException fx(Map<String, Object?> err, [int s = 400]) =>
      FunctionException(status: s, details: {'error': err});
  test('field=date: TooOld chỉ khi update/delete', () {
    final e = fx({'code': 'VALIDATION_ERROR', 'field': 'date'});
    expect(mapMealLogError(e, op: MealLogOp.update), isA<MealLogTooOld>());
    expect(mapMealLogError(e, op: MealLogOp.delete), isA<MealLogTooOld>());
    final add = mapMealLogError(e, op: MealLogOp.add);
    expect(add, isA<MealLogInvalid>());
    expect((add as MealLogInvalid).field, 'date');
  });
  test('ITEM_NOT_FOUND, IDEMPOTENCY_CONFLICT', () {
    expect(mapMealLogError(fx({'code': 'ITEM_NOT_FOUND'}, 404), op: MealLogOp.update),
        isA<MealLogItemNotFound>());
    final c = mapMealLogError(
        fx({'code': 'IDEMPOTENCY_CONFLICT', 'field': 'client_request_id'}, 422));
    expect((c as MealLogFailed).code, 'IDEMPOTENCY_CONFLICT');
  });
  test('field không phải chuỗi, body lạ không crash', () {
    expect(mapMealLogError(fx({'code': 'VALIDATION_ERROR', 'field': 7})),
        isA<MealLogInvalid>());
    expect(mapMealLogError(const FunctionException(status: 500, details: '<html>')),
        isA<MealLogFailed>());
    expect(mapMealLogError(const FunctionException(status: 500, details: {'error': 'x'})),
        isA<MealLogFailed>());
  });
}
