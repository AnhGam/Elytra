import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:elytra/core/theme.dart';

/// Khung 4 tab; Back ở tab khác Trang chủ thì về Trang chủ, ở Trang chủ thì thoát app
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: navigationShell.currentIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) navigationShell.goBranch(0);
      },
      child: Scaffold(
        body: navigationShell,
        bottomNavigationBar: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          indicatorColor: AppColors.primaryContainer,
          onDestinationSelected: (i) => navigationShell.goBranch(
            i,
            // Bấm lại tab đang mở thì về màn gốc của tab
            initialLocation: i == navigationShell.currentIndex,
          ),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Trang chủ'),
            NavigationDestination(icon: Icon(Icons.menu_book_outlined), label: 'Nhật ký'),
            NavigationDestination(icon: Icon(Icons.restaurant), label: 'Món ăn'),
            NavigationDestination(icon: Icon(Icons.person_outline), label: 'Cá nhân'),
          ],
        ),
      ),
    );
  }
}
