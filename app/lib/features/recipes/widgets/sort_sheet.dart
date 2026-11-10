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
                    size: 24,
                    color: selected ? AppColors.primary : AppColors.textMuted,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SortLabel(
                      sort.labelVi,
                      style: TextStyle(
                        fontSize: 15,
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

/// Nhãn tiêu chí sắp xếp; "→" vẽ bằng icon vì font Be Vietnam Pro không có ký tự này
class SortLabel extends StatelessWidget {
  const SortLabel(
    this.label, {
    super.key,
    this.style,
    this.maxLines,
    this.overflow,
  });

  final String label;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    final parts = label.split('→');
    if (parts.length == 1) {
      return Text(label, style: style, maxLines: maxLines, overflow: overflow);
    }
    final size =
        style?.fontSize ?? DefaultTextStyle.of(context).style.fontSize ?? 14;
    return Text.rich(
      TextSpan(
        children: [
          for (var i = 0; i < parts.length; i++) ...[
            if (i > 0)
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                // Màu null → lấy theo IconTheme (vd. màu chữ của nút)
                child: Icon(
                  Icons.arrow_forward,
                  size: size,
                  color: style?.color,
                ),
              ),
            TextSpan(text: parts[i]),
          ],
        ],
      ),
      style: style,
      maxLines: maxLines,
      overflow: overflow,
      semanticsLabel: label.replaceAll('→', 'đến'),
    );
  }
}
