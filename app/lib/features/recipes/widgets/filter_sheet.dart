import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:elytra/core/theme.dart';
import 'package:elytra/features/recipes/recipe.dart';
import 'package:elytra/features/recipes/recipe_query.dart';
import 'package:elytra/features/recipes/recipe_search_controller.dart';
import 'package:elytra/features/recipes/widgets/allergen_sheet.dart';
import 'package:elytra/features/recipes/widgets/recipe_chips.dart';
import 'package:elytra/features/recipes/widgets/sheet_frame.dart';

const _maxKcalInput = 1500;
const _timeOptions = [15, 30, 60];

/// Sheet "Bộ lọc": chỉnh trên bản nháp, chỉ áp dụng khi bấm "Xem N món".
/// Trả bộ lọc mới (công tắc dị ứng ghi thẳng vào [controller]); đóng sheet → null.
Future<RecipeFilters?> showFilterSheet(
  BuildContext context, {
  required RecipeSearchController controller,
}) {
  return showAppSheet<RecipeFilters>(
    context,
    (_) => _FilterSheet(controller: controller),
  );
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.controller});

  final RecipeSearchController controller;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late final RecipeSearchController _c = widget.controller;
  late final _min = TextEditingController(text: _kcalText(_c.filters.minKcal));
  late final _max = TextEditingController(text: _kcalText(_c.filters.maxKcal));
  late int? _maxMinutes = _c.filters.maxTotalMinutes;
  late Set<Difficulty> _difficulties = {..._c.filters.difficulties};
  late bool _exclude = _c.excludeAllergens;

  static String _kcalText(double? v) => v == null ? '' : v.round().toString();

  @override
  void dispose() {
    _min.dispose();
    _max.dispose();
    super.dispose();
  }

  int? get _minValue => int.tryParse(_min.text);
  int? get _maxValue => int.tryParse(_max.text);

  /// Lỗi nhập calo; null = hợp lệ
  String? get _kcalError {
    final lo = _minValue, hi = _maxValue;
    if ((lo ?? 0) > _maxKcalInput || (hi ?? 0) > _maxKcalInput) {
      return 'Nhập số từ 0 đến 1.500';
    }
    if (lo != null && hi != null && lo > hi) {
      return 'Tối thiểu phải nhỏ hơn tối đa';
    }
    return null;
  }

  RecipeFilters get _draft => RecipeFilters(
    minKcal: _minValue?.toDouble(),
    maxKcal: _maxValue?.toDouble(),
    maxTotalMinutes: _maxMinutes,
    difficulties: _difficulties,
    category: _c.filters.category,
  );

  void _reset() {
    setState(() {
      _min.clear();
      _max.clear();
      _maxMinutes = null;
      _difficulties = {};
    });
  }

  void _apply() {
    _c.setExcludeAllergens(_exclude);
    Navigator.of(context).pop(_draft);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      // Lưu dị ứng từ dòng "sửa" → catalog đổi → cập nhật dòng phụ và số món
      listenable: _c,
      builder: (context, _) {
        final error = _kcalError;
        final count = _c.countFor(_draft, excludeAllergens: _exclude);
        return SheetFrame(
          title: 'Bộ lọc',
          body: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SheetSectionTitle('Calo mỗi khẩu phần'),
                const SizedBox(height: 12),
                _buildKcalRow(),
                const SizedBox(height: 8),
                Text(
                  error ?? 'Nhập số nguyên từ 0 đến 1.500 · để trống nếu không giới hạn',
                  style: TextStyle(
                    fontSize: 13,
                    color: error == null
                        ? AppColors.textMuted
                        : AppColors.error,
                  ),
                ),
                const SizedBox(height: 24),
                const SheetSectionTitle('Thời gian nấu'),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  children: [
                    QuickFilterChip(
                      label: 'Bất kỳ',
                      selected: _maxMinutes == null,
                      onTap: () => setState(() => _maxMinutes = null),
                    ),
                    for (final m in _timeOptions)
                      QuickFilterChip(
                        label: '≤ $m phút',
                        selected: _maxMinutes == m,
                        onTap: () => setState(
                          () => _maxMinutes = _maxMinutes == m ? null : m,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                const SheetSectionTitle('Độ khó'),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final d in Difficulty.values)
                      QuickFilterChip(
                        label: d.labelVi,
                        selected: _difficulties.contains(d),
                        onTap: () => setState(() {
                          _difficulties = {..._difficulties};
                          if (!_difficulties.remove(d)) _difficulties.add(d);
                        }),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                const SheetSectionTitle('Nguyên liệu trong tủ lạnh'),
                const SizedBox(height: 4),
                const Text(
                  'Ưu tiên món dùng nhiều nguyên liệu bạn đang có · Sắp có',
                  style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                ),
                const SizedBox(height: 24),
                _buildAllergenRow(),
              ],
            ),
          ),
          footer: Row(
            children: [
              TextButton(
                onPressed: _reset,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primaryDark,
                  minimumSize: const Size(96, 56),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: const Text('Xóa lọc'),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FilledButton(
                  onPressed: error == null ? _apply : null,
                  style: sheetPrimaryButtonStyle(),
                  child: Text('Xem $count món'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildKcalRow() {
    Widget field(String label, Key key, TextEditingController ctl) {
      return Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 14, color: AppColors.textMuted),
            ),
            const SizedBox(height: 6),
            TextField(
              key: key,
              controller: ctl,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
              onChanged: (_) => setState(() {}),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: AppColors.surfaceVariant,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                // suffixIcon thay suffixText để "kcal" hiện cả khi ô trống, chưa focus
                suffixIcon: const Padding(
                  padding: EdgeInsets.only(right: 16),
                  child: Text(
                    'kcal',
                    style: TextStyle(fontSize: 14, color: AppColors.textMuted),
                  ),
                ),
                suffixIconConstraints: const BoxConstraints(),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.outline),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 2,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        field('Tối thiểu', const Key('minKcal'), _min),
        const Padding(
          padding: EdgeInsets.fromLTRB(12, 0, 12, 14),
          child: Text(
            '–',
            style: TextStyle(fontSize: 18, color: AppColors.textMuted),
          ),
        ),
        field('Tối đa', const Key('maxKcal'), _max),
      ],
    );
  }

  Widget _buildAllergenRow() {
    final declared = _c.hasDeclaredAllergens;
    final ids = _c.catalog.userAllergenIds;
    final names = [
      for (final a in _c.catalog.allergens)
        if (ids.contains(a.id)) a.nameVi,
    ];
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SheetSectionTitle('Loại món chứa chất tôi dị ứng'),
              Row(
                children: [
                  Flexible(
                    child: Text(
                      declared ? '${names.join(', ')} · ' : 'Chưa khai báo · ',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                  // Vùng chạm cao 48 cho chữ liên kết nhỏ
                  InkWell(
                    onTap: () => showAllergenSheet(context),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 48),
                      child: Center(
                        widthFactor: 1,
                        child: Text(
                          declared ? 'sửa' : 'khai báo',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Switch(
          value: declared && _exclude,
          // Chưa khai báo thì công tắc không có tác dụng
          onChanged: declared ? (v) => setState(() => _exclude = v) : null,
          activeTrackColor: AppColors.primary,
          thumbIcon: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected)
                ? const Icon(Icons.check, color: AppColors.primary)
                : null,
          ),
        ),
      ],
    );
  }
}
