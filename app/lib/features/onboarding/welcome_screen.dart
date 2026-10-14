import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Màn Chào: 2 lối vào. Giao diện đầy đủ theo Elytra.fig làm sau.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Elytra'),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => context.push('/onboarding'),
              child: const Text('Bắt đầu'),
            ),
            TextButton(
              onPressed: () => context.push('/login'),
              child: const Text('Đã có tài khoản? Đăng nhập'),
            ),
          ],
        ),
      ),
    );
  }
}
