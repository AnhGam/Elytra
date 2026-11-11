import 'package:flutter/material.dart';

/// Tab Nhật ký. Khung tạm, hoàn thiện ở Task 15–16.
class DiaryScreen extends StatelessWidget {
  const DiaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nhật ký')),
      body: const SizedBox.expand(),
    );
  }
}
