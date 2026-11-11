import 'dart:io';

import 'package:elytra/features/auth/profile_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  Future<GoRouter> pumpGate(WidgetTester t, Future<bool> Function() hasProfile) async {
    final r = GoRouter(initialLocation: '/gate', routes: [
      GoRoute(path: '/gate', builder: (_, _) => ProfileGate(hasProfile: hasProfile)),
      GoRoute(path: '/home', builder: (_, _) => const Text('HOME')),
      GoRoute(path: '/onboarding', builder: (_, _) => const Text('ONBOARDING')),
    ]);
    addTearDown(r.dispose);
    await t.pumpWidget(MaterialApp.router(routerConfig: r));
    await t.pumpAndSettle();
    return r;
  }

  testWidgets('đã có hồ sơ → /home', (t) async {
    await pumpGate(t, () async => true);
    expect(find.text('HOME'), findsOneWidget);
  });

  testWidgets('chưa khai báo → /onboarding', (t) async {
    await pumpGate(t, () async => false);
    expect(find.text('ONBOARDING'), findsOneWidget);
  });

  testWidgets('mất mạng khi kiểm tra hồ sơ → vẫn vào /home (Dashboard tự báo lỗi)',
      (t) async {
    await pumpGate(t, () async => throw const SocketException('Failed host lookup'));
    expect(find.text('HOME'), findsOneWidget);
    expect(find.text('Thử lại'), findsNothing);
  });
}
