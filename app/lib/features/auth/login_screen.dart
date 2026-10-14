import 'package:flutter/material.dart';

/// TẠM (để router biên dịch được). Giao diện thật làm ở Bước 4.5.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('Đăng nhập')));
}
