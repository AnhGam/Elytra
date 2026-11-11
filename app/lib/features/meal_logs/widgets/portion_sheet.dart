import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'package:elytra/core/meal_time.dart';
import 'package:elytra/core/theme.dart';
import 'package:elytra/features/meal_logs/budget_view.dart';
import 'package:elytra/features/meal_logs/log_meal_controller.dart';
import 'package:elytra/features/meal_logs/meal_log_models.dart';
import 'package:elytra/features/meal_logs/portion_math.dart';
import 'package:elytra/features/recipes/recipe.dart';

final _servingNum = NumberFormat('#,##0.##', 'vi');

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
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 8),
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.outlineStrong,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _header(sending),
                    const SizedBox(height: 16),
                    const _Label('Thêm vào'),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final m in MealType.values)
                          _Pill(
                            label: _mealShort(m),
                            selected: m == _meal,
                            onTap: sending
                                ? null
                                : () => setState(() => _meal = m),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_food.byServings)
                      ..._servingsInput(sending)
                    else
                      ..._gramInput(sending),
                    const SizedBox(height: 16),
                    _PreviewBox(
                      preview: preview,
                      afterAdd: preview == null || day == null
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
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: sending || req == null ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryDark,
                    foregroundColor: AppColors.surface,
                    disabledBackgroundColor: AppColors.primaryDisabled,
                    disabledForegroundColor: AppColors.surface,
                    shape: const StadiumBorder(),
                  ),
                  child: sending
                      ? const Text('Đang thêm…', style: _buttonText)
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.add, size: 20),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'Thêm vào bữa ${_meal.labelVi}',
                                overflow: TextOverflow.ellipsis,
                                style: _buttonText,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const _buttonText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  Widget _header(bool sending) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _food.name,
                style: const TextStyle(
                  fontSize: 20,
                  height: 28 / 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                _food.sourceLine,
                style: const TextStyle(
                  fontSize: 14,
                  height: 20 / 14,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Đóng',
          onPressed: sending ? null : () => Navigator.of(context).pop(),
          style: IconButton.styleFrom(
            backgroundColor: AppColors.background,
            fixedSize: const Size(48, 48),
          ),
          icon: const Icon(Icons.close, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  List<Widget> _servingsInput(bool sending) {
    final canDec = !sending && _servings > kMinServings;
    final canInc = !sending && _servings < kMaxServings;
    return [
      _Label(
        'Khẩu phần (${_servingNum.format(kMinServings)} – ${_servingNum.format(kMaxServings)})',
      ),
      Row(
        children: [
          _RoundButton(
            tooltip: 'Bớt',
            icon: Icons.remove,
            background: AppColors.background,
            foreground: AppColors.textPrimary,
            onTap: canDec
                ? () => setState(() => _servings = stepServings(_servings, -1))
                : null,
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  _servingNum.format(_servings),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'phần',
                  style: TextStyle(fontSize: 16, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          _RoundButton(
            tooltip: 'Thêm phần',
            icon: Icons.add,
            background: AppColors.primaryContainer,
            foreground: AppColors.primaryDark,
            onTap: canInc
                ? () => setState(() => _servings = stepServings(_servings, 1))
                : null,
          ),
        ],
      ),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        children: [
          for (final s in kServingChips)
            _Pill(
              label: servingChipLabel(s),
              selected: _servings == s,
              onTap: sending ? null : () => setState(() => _servings = s),
            ),
        ],
      ),
    ];
  }

  List<Widget> _gramInput(bool sending) {
    final invalid = _grams == null;
    OutlineInputBorder border(Color c, double w) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: c, width: w),
    );
    return [
      const _Label('Khối lượng ăn được'),
      TextField(
        controller: _gram,
        enabled: !sending,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(4),
        ],
        onChanged: (_) => setState(() {}),
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          suffixText: 'g',
          suffixStyle: const TextStyle(
            fontSize: 18,
            color: AppColors.textMuted,
          ),
          enabledBorder: border(
            invalid ? AppColors.error : AppColors.outlineStrong,
            1,
          ),
          focusedBorder: border(
            invalid ? AppColors.error : AppColors.primary,
            2,
          ),
          disabledBorder: border(AppColors.outline, 1),
        ),
      ),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        children: [
          for (final g in kGramChips)
            _Pill(
              label: '$g g',
              selected: _grams == g,
              onTap: sending
                  ? null
                  : () => setState(() {
                      _gram.text = '$g';
                      _gram.selection = TextSelection.collapsed(
                        offset: _gram.text.length,
                      );
                    }),
            ),
        ],
      ),
      const SizedBox(height: 4),
      Text(
        'Nhập từ $kMinGram đến ${formatKcal(kMaxGram)} g.',
        style: TextStyle(
          fontSize: 13,
          height: 18 / 13,
          color: invalid ? AppColors.onErrorContainer : AppColors.textMuted,
        ),
      ),
    ];
  }

  static String _mealShort(MealType m) => switch (m) {
    MealType.breakfast => 'Sáng',
    MealType.lunch => 'Trưa',
    MealType.dinner => 'Tối',
    MealType.snack => 'Phụ',
  };
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          height: 20 / 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textMuted,
        ),
      ),
    );
  }
}

/// Chip bo tròn cao 36 trong vùng chạm 48.
class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9999),
        child: SizedBox(
          height: 48,
          child: Center(
            child: Container(
              height: 36,
              constraints: const BoxConstraints(minWidth: 48),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primaryContainer
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(9999),
                border: Border.all(
                  color: selected
                      ? AppColors.primaryOutline
                      : AppColors.outlineStrong,
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected
                      ? AppColors.primaryDark
                      : AppColors.textPrimary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.tooltip,
    required this.icon,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  final String tooltip;
  final IconData icon;
  final Color background;
  final Color foreground;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onTap,
      style: IconButton.styleFrom(
        backgroundColor: background,
        foregroundColor: foreground,
        disabledBackgroundColor: AppColors.surfaceVariant,
        disabledForegroundColor: AppColors.placeholder,
        fixedSize: const Size(56, 56),
      ),
      icon: Icon(icon),
    );
  }
}

/// 4 ô xem trước kcal / P / C / F và dòng "Sau khi thêm…".
class _PreviewBox extends StatelessWidget {
  const _PreviewBox({required this.preview, required this.afterAdd});

  final Macros? preview;
  final String? afterAdd;

  @override
  Widget build(BuildContext context) {
    final p = preview;
    String g(double v) => p == null ? '–' : formatGram(v);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _Tile(
                value: p == null ? '–' : formatKcal(p.kcal),
                unit: 'kcal',
                label: 'Calo',
                bg: AppColors.surface,
                border: AppColors.outline,
                fg: AppColors.textPrimary,
                labelColor: AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              _Tile(
                value: g(p?.proteinG ?? 0),
                unit: 'g',
                label: 'Protein',
                bg: AppColors.proteinContainer,
                border: AppColors.proteinOutline,
                fg: AppColors.onProteinContainer,
              ),
              const SizedBox(width: 8),
              _Tile(
                value: g(p?.carbsG ?? 0),
                unit: 'g',
                label: 'Carbs',
                bg: AppColors.carbsContainer,
                border: AppColors.carbsOutline,
                fg: AppColors.onCarbsContainer,
              ),
              const SizedBox(width: 8),
              _Tile(
                value: g(p?.fatG ?? 0),
                unit: 'g',
                label: 'Fat',
                bg: AppColors.fatContainer,
                border: AppColors.fatOutline,
                fg: AppColors.onFatContainer,
              ),
            ],
          ),
          if (afterAdd != null) ...[
            const SizedBox(height: 10),
            Text(
              afterAdd!,
              style: const TextStyle(
                fontSize: 14,
                height: 20 / 14,
                fontWeight: FontWeight.w500,
                color: AppColors.primaryDark,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.value,
    required this.unit,
    required this.label,
    required this.bg,
    required this.border,
    required this.fg,
    this.labelColor,
  });

  final String value;
  final String unit;
  final String label;
  final Color bg;
  final Color border;
  final Color fg;
  final Color? labelColor;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border),
        ),
        child: Column(
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: fg,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Text(unit, style: TextStyle(fontSize: 12, color: fg)),
                ],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: labelColor ?? fg),
            ),
          ],
        ),
      ),
    );
  }
}
