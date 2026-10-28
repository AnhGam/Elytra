import 'package:flutter/material.dart';

import 'package:elytra/core/theme.dart';

/// Màn tạm cho tab chưa có nội dung
class ComingSoonScreen extends StatelessWidget {
  const ComingSoonScreen({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: const Center(
        child: Text('Sắp có', style: TextStyle(color: AppColors.textMuted)),
      ),
    );
  }
}
