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
}
