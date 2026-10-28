import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:elytra/core/theme.dart';

/// Khung 4 tab; Back ở tab khác Trang chủ thì về Trang chủ, ở Trang chủ thì thoát app
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  // Tab thường: icon xám; tab đang chọn: icon xanh đậm
  static NavigationDestination _tab(IconData icon, String label) =>
      NavigationDestination(
        icon: Icon(icon, color: AppColors.textMuted),
        selectedIcon: Icon(icon, color: AppColors.primaryDark),
        label: label,
      );

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: navigationShell.currentIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) navigationShell.goBranch(0);
      },
      child: Scaffold(
        body: navigationShell,
        bottomNavigationBar: DecoratedBox(
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.outline)),
          ),
          child: NavigationBar(
            height: 80,
            backgroundColor: AppColors.surface,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            selectedIndex: navigationShell.currentIndex,
            indicatorColor: AppColors.primaryContainer,
            labelTextStyle: WidgetStateProperty.resolveWith(
              (s) => s.contains(WidgetState.selected)
                  ? const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    )
                  : const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textMuted,
                    ),
            ),
            onDestinationSelected: (i) => navigationShell.goBranch(
              i,
              // Bấm lại tab đang mở thì về màn gốc của tab
              initialLocation: i == navigationShell.currentIndex,
            ),
            destinations: [
              _tab(Icons.home_outlined, 'Trang chủ'),
              _tab(Icons.menu_book_outlined, 'Nhật ký'),
              _tab(Icons.restaurant, 'Món ăn'),
              _tab(Icons.person_outline, 'Cá nhân'),
            ],
          ),
        ),
      ),
    );
  }
}
