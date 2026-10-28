import 'package:flutter/material.dart';

import 'package:elytra/core/theme.dart';
import 'package:elytra/features/recipes/recipe_catalog.dart';
import 'package:elytra/features/recipes/widgets/sheet_frame.dart';

/// Sheet "Dị ứng của bạn": chọn các chất rồi Lưu vào user_allergens
Future<void> showAllergenSheet(BuildContext context) {
  final catalog = RecipeScope.of(context);
  // Danh sách chất chưa tải (vd. tải lần đầu lỗi) → tải lại trước
  if (catalog.allergens.isEmpty) catalog.ensureLoaded();
  return showAppSheet<void>(context, (_) => const _AllergenSheet());
}

class _AllergenSheet extends StatefulWidget {
  const _AllergenSheet();

  @override
  State<_AllergenSheet> createState() => _AllergenSheetState();
}

class _AllergenSheetState extends State<_AllergenSheet> {
  Set<int>? _selected; // bản nháp; null = chưa lấy từ catalog
  bool _saving = false;
  bool _failed = false;

  Future<void> _save(RecipeCatalog catalog) async {
    setState(() {
      _saving = true;
      _failed = false;
    });
    try {
      await catalog.saveAllergens(_selected ?? catalog.userAllergenIds);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _failed = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalog = RecipeScope.of(context);
    final selected = _selected ?? catalog.userAllergenIds;
    final allergens = catalog.allergens;
    return SheetFrame(
      title: 'Dị ứng của bạn',
      body: allergens.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: catalog.status == CatalogStatus.error
                    ? TextButton(
                        onPressed: catalog.ensureLoaded,
                        child: const Text('Không tải được danh sách · Thử lại'),
                      )
                    : const CircularProgressIndicator(),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(24, 0, 24, 8),
                  child: Text(
                    'Món chứa các chất này sẽ được cảnh báo và có thể ẩn khỏi kết quả.',
                    style: TextStyle(fontSize: 14, color: AppColors.textMuted),
                  ),
                ),
                for (final a in allergens)
                  CheckboxListTile(
                    value: selected.contains(a.id),
                    onChanged: _saving
                        ? null
                        : (v) => setState(() {
                            _selected = {...selected};
                            v == true
                                ? _selected!.add(a.id)
                                : _selected!.remove(a.id);
                          }),
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: AppColors.primary,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    title: Text(
                      a.nameVi,
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    subtitle: a.description == null
                        ? null
                        : Text(
                            a.description!,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textMuted,
                            ),
                          ),
                  ),
                const SizedBox(height: 8),
              ],
            ),
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_failed)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                'Không lưu được. Thử lại.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppColors.error),
              ),
            ),
          FilledButton(
            onPressed: _saving || allergens.isEmpty
                ? null
                : () => _save(catalog),
            style: sheetPrimaryButtonStyle(),
            child: _saving
                ? const SizedBox.square(
                    dimension: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.surface,
                    ),
                  )
                : const Text('Lưu'),
          ),
        ],
      ),
    );
  }
}
