import 'package:flutter/material.dart';

import 'package:elytra/core/meal_time.dart';
import 'package:elytra/core/theme.dart';
import 'package:elytra/features/meal_logs/budget_view.dart';
import 'package:elytra/features/meal_logs/log_meal_controller.dart';
import 'package:elytra/features/meal_logs/meal_log_models.dart';
import 'package:elytra/features/meal_logs/portion_math.dart';
import 'package:elytra/features/meal_logs/widgets/portion_inputs.dart';
import 'package:elytra/features/recipes/recipe.dart';

/// Món đang chọn lượng: món nấu (theo phần) hoặc món ăn sẵn / nguyên liệu (theo gam).
class PortionFood {
  const PortionFood.recipe(Recipe this.recipe) : hit = null;
  const PortionFood.hit(FoodHit this.hit) : recipe = null;

  final Recipe? recipe;
  final FoodHit? hit;

  bool get byServings => recipe != null;
  String get name => recipe?.title ?? hit!.name;

  /// "Món nấu · 240 kcal / phần", "Món ăn sẵn · 110 kcal / 100 g".
  String get sourceLine {
    if (recipe != null) {
      return 'Món nấu · ${formatKcal(recipe!.kcal)} kcal / phần';
    }
    final kind = hit!.kind == FoodKind.dish ? 'Món ăn sẵn' : 'Nguyên liệu';
    return '$kind · ${formatKcal(hit!.per100.kcal)} kcal / 100 g';
  }
}

/// Mở [PortionSheet]; trả về kết quả đóng sheet (`LogAdded` / `LogProfileMissingOutcome`)
/// hoặc null khi người dùng tự đóng.
Future<LogOutcome?> showPortionSheet(
  BuildContext context, {
  required LogMealController controller,
  required PortionFood food,
}) {
  return showModalBottomSheet<LogOutcome>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    // Kéo xuống không đóng được (đang gửi thì phải khoá đóng sheet); chạm nền và
    // Back đi qua PopScope trong sheet nên bị khoá khi đang gửi.
    enableDrag: false,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => PortionSheet(controller: controller, food: food),
  );
}

/// Sheet chọn bữa, lượng, xem trước dinh dưỡng và nút "Thêm vào bữa …" (§7.2).
class PortionSheet extends StatefulWidget {
  const PortionSheet({super.key, required this.controller, required this.food});

  final LogMealController controller;
  final PortionFood food;

  @override
  State<PortionSheet> createState() => _PortionSheetState();
}

class _PortionSheetState extends State<PortionSheet> {
  late MealType _meal = widget.controller.meal;
  double _servings = 1;
  final _gram = TextEditingController(text: '100');
  String? _error;

  LogMealController get _c => widget.controller;
  PortionFood get _food => widget.food;

  @override
  void initState() {
    super.initState();
    _c.addListener(_onChanged);
    _c.store.addListener(_onChanged); // dòng "Sau khi thêm" theo nhật ký ngày
  }

  @override
  void dispose() {
    _c.removeListener(_onChanged);
    _c.store.removeListener(_onChanged);
    _gram.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  int? get _grams => parseGram(_gram.text);

  Macros? get _preview {
    if (_food.byServings) return previewRecipe(_food.recipe!, _servings);
    final g = _grams;
    return g == null ? null : previewPer100(_food.hit!, g);
  }

  LogRequest? get _request {
    final date = _c.date;
    final r = _food.recipe;
    if (r != null) {
      return LogRequest.recipe(
        refId: r.id,
        servings: _servings,
        meal: _meal,
        date: date,
      );
    }
    final g = _grams;
    if (g == null) return null;
    final h = _food.hit!;
    return h.kind == FoodKind.dish
        ? LogRequest.dish(refId: h.id, amountG: g, meal: _meal, date: date)
        : LogRequest.ingredient(
            refId: h.id,
            amountG: g,
            meal: _meal,
            date: date,
          );
  }

  Future<void> _submit() async {
    final req = _request;
    if (req == null) return;
    setState(() => _error = null);
    final outcome = await _c.submit(req);
    if (!mounted) return;
    switch (outcome) {
      case LogAdded() || LogProfileMissingOutcome():
        Navigator.of(context).pop(outcome);
      case LogOfflineOutcome():
        setState(() => _error = 'Không có mạng. Thử lại');
      case LogFailedOutcome():
        setState(() => _error = 'Không thêm được món. Thử lại sau.');
      case LogIgnored():
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sending = _c.sending;
    final req = _request;
    final preview = _preview;
    final day = _c.store.day(_c.date).log;
    return PopScope(
      canPop: !sending,
      child: PortionSheetFrame(
        title: _food.name,
        subtitle: _food.sourceLine,
        onClose: sending ? null : () => Navigator.of(context).pop(),
        content: [
          const SheetLabel('Thêm vào'),
          Wrap(
            spacing: 8,
            children: [
              for (final m in MealType.values)
                PortionPill(
                  label: mealShortLabel(m),
                  selected: m == _meal,
                  onTap: sending ? null : () => setState(() => _meal = m),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (_food.byServings)
            ServingsStepper(
              value: _servings,
              enabled: !sending,
              onChanged: (v) => setState(() => _servings = v),
            )
          else
            GramInput(
              controller: _gram,
              enabled: !sending,
              onChanged: () => setState(() {}),
            ),
          const SizedBox(height: 16),
          MacroPreviewBox(
            preview: preview,
            note: preview == null || day == null
                ? null
                : afterAddLabel(
                    day: day.budget,
                    meal: day.meals[_meal] ?? MealLog.empty,
                    type: _meal,
                    add: preview,
                  ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: const TextStyle(
                fontSize: 14,
                height: 20 / 14,
                fontWeight: FontWeight.w600,
                color: AppColors.onErrorContainer,
              ),
            ),
          ],
        ],
        footer: SizedBox(
          height: 52,
          child: FilledButton(
            onPressed: sending || req == null ? null : _submit,
            style: primarySheetButtonStyle(),
            child: sending
                ? const Text('Đang thêm…')
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add, size: 20),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Thêm vào bữa ${_meal.labelVi}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
