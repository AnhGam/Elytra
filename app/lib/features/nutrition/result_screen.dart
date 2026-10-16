import 'package:flutter/material.dart';

import 'package:elytra/features/onboarding/body_info.dart';
/// TẠM (để router biên dịch được). Giao diện thật làm ở Bước 6.
class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key, required this.input});

  final BodyInfo input;
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('Kết quả')));
}
