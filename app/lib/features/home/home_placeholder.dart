import 'package:flutter/material.dart';

import 'package:elytra/main.dart';

/// Home tạm, có nút đăng xuất. Sprint sau thay bằng Dashboard.
class HomePlaceholder extends StatelessWidget {
  const HomePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Home – ${supabase.auth.currentUser?.email ?? ''}'),
            const SizedBox(height: 16),
            // Đăng xuất → router thấy mất phiên → tự đưa về /welcome
            OutlinedButton(
              onPressed: () => supabase.auth.signOut(),
              child: const Text('Đăng xuất'),
            ),
          ],
        ),
      ),
    );
  }
}
