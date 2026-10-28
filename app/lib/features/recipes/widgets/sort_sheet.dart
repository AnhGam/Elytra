import 'package:flutter/material.dart';

import 'package:elytra/core/theme.dart';
import 'package:elytra/features/recipes/recipe_query.dart';
import 'package:elytra/features/recipes/widgets/sheet_frame.dart';

/// Sheet "Sắp xếp theo": chạm một dòng là chọn và đóng; đóng sheet → null
Future<RecipeSort?> showSortSheet(BuildContext context, RecipeSort current) {
  return showAppSheet<RecipeSort>(
    context,
    (context) => SheetFrame(
      title: 'Sắp xếp theo',
      body: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          children: [
            for (final s in RecipeSort.values)
              _SortRow(sort: s, selected: s == current),
          ],
        ),
      ),
    ),
  );
}

class _SortRow extends StatelessWidget {
  const _SortRow({required this.sort, required this.selected});

  final RecipeSort sort;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primarySurface : AppColors.surface,
      child: InkWell(
        onTap: () => Navigator.of(context).pop(sort),
        child: Semantics(
          selected: selected,
          inMutuallyExclusiveGroup: true,
          child: SizedBox(
            height: 52,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Icon(
                    selected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    size: 22,
                    color: selected ? AppColors.primary : AppColors.textMuted,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      sort.labelVi,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: selected
                            ? AppColors.primaryDark
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
