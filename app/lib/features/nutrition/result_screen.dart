import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:elytra/core/pending_onboarding.dart';
import 'package:elytra/core/theme.dart';
import 'package:elytra/features/auth/widgets/auth_widgets.dart';
import 'package:elytra/features/nutrition/nutrition_calculator.dart';
import 'package:elytra/features/nutrition/nutrition_repository.dart';
import 'package:elytra/features/onboarding/body_info.dart';
import 'package:elytra/features/onboarding/body_info_rules.dart';
import 'package:elytra/main.dart';

/// Kiểu số Việt Nam: 2.069 · 22,5
final _int = NumberFormat('#,##0', 'vi');
final _dec = NumberFormat('#,##0.#', 'vi');
String _kcal(double v) => _int.format(v.round());

const _amber = Color(0xFF92400E);
const _proteinColor = Color(0xFF0284C7);
const _carbsColor = Color(0xFFD97706);
const _fatColor = Color(0xFF6366F1);

String _goalLabel(Goal g) => switch (g) {
  Goal.loseWeight => 'Giảm cân',
  Goal.maintain => 'Duy trì',
  Goal.gainWeight => 'Tăng cân',
};

/// Màn kết quả BMR/TDEE/Macro (Figma: ResultScreen 41:343).
/// Tính ngay trong app nên không có trạng thái đang tải; chỉ lúc Lưu mới gọi mạng.
class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key, required this.input});

  final BodyInfo input;

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  late final NutritionResult _result = NutritionCalculator.compute(
    widget.input,
  );
  bool _saving = false;

  bool get _loggedIn => supabase.auth.currentSession != null;

  Future<void> _onSave() async {
    // Chưa đăng nhập: giữ thể trạng lại, đăng ký xong ProfileGate sẽ lưu
    if (!_loggedIn) {
      pendingBodyInfo.value = widget.input;
      context.push('/register');
      return;
    }
    // Đã đăng nhập (chưa có hồ sơ): lưu luôn rồi vào Home
    setState(() => _saving = true);
    try {
      await nutritionRepo.save(widget.input);
      if (mounted) context.go('/home');
    } on AuthException {
      if (mounted) context.go('/login'); // phiên hết hạn → đăng nhập lại
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Không lưu được kết quả. Kiểm tra mạng và thử lại.',
          ),
          action: SnackBarAction(label: 'Thử lại', onPressed: _onSave),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final info = widget.input;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const _Header(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 30, 24, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Intro(info: info, result: _result),
                    const SizedBox(height: 20),
                    _CaloriesCard(
                      goal: info.goal,
                      result: _result,
                      gender: info.gender,
                    ),
                    const SizedBox(height: 12),
                    _MacroCard(goal: info.goal, result: _result),
                    const SizedBox(height: 12),
                    _MealCard(result: _result),
                  ],
                ),
              ),
            ),
            // Nút chính ghim ở đáy
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(9999),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x3316A34A),
                      offset: Offset(0, 10),
                      blurRadius: 15,
                      spreadRadius: -3,
                    ),
                    BoxShadow(
                      color: Color(0x3316A34A),
                      offset: Offset(0, 4),
                      blurRadius: 6,
                      spreadRadius: -4,
                    ),
                  ],
                ),
                child: PrimaryButton(
                  label: _loggedIn
                      ? 'Lưu kết quả'
                      : 'Lưu kết quả & tạo tài khoản',
                  loading: _saving,
                  onPressed: _onSave,
                  trailing: SvgPicture.asset('assets/icons/ic_arrow_right.svg'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Quay lại · "Kết Quả Dinh Dưỡng" · nút Tùy chỉnh
class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: SizedBox(
        height: 40,
        child: Row(
          children: [
            IconButton(
              tooltip: 'Quay lại',
              constraints: const BoxConstraints.tightFor(width: 40, height: 40),
              padding: EdgeInsets.zero,
              // Về bước cuối của màn thể trạng, dữ liệu vẫn giữ nguyên
              onPressed: () =>
                  context.canPop() ? context.pop() : context.go('/onboarding'),
              icon: SvgPicture.asset('assets/icons/ic_back.svg'),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Kết Quả Dinh Dưỡng',
                style: TextStyle(
                  fontSize: 20,
                  height: 28 / 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Tooltip(
              message: 'Tùy chỉnh',
              child: Material(
                color: AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppColors.outline),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => ScaffoldMessenger.of(context)
                      .showSnackBar(const SnackBar(content: Text('Sắp có'))),
                  child: SizedBox(
                    width: 40,
                    height: 40,
                    child: Center(
                      child: SvgPicture.asset('assets/icons/ic_tune.svg'),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Chip BMI + tiêu đề lộ trình ("Giảm về 60 kg · ~13 tuần")
class _Intro extends StatelessWidget {
  const _Intro({required this.info, required this.result});

  final BodyInfo info;
  final NutritionResult result;

  String get _headline {
    final target = _dec.format(info.targetWeightKg ?? info.weightKg);
    final weeks = info.weeksToTarget;
    final suffix = weeks == null ? '' : ' · ~$weeks tuần';
    return switch (info.goal) {
      Goal.loseWeight => 'Giảm về $target kg$suffix',
      Goal.gainWeight => 'Tăng lên $target kg$suffix',
      Goal.maintain => 'Duy trì ${_dec.format(info.weightKg)} kg',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.primaryContainer,
            borderRadius: BorderRadius.circular(9999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset('assets/icons/ic_heart.svg'),
              const SizedBox(width: 4),
              Text(
                'BMI ${_dec.format(result.bmi)} · ${bmiCategory(result.bmi)}',
                style: const TextStyle(
                  fontSize: 11,
                  height: 16.5 / 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _headline,
          style: const TextStyle(
            fontSize: 24,
            height: 32 / 24,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.6,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

/// Thẻ xanh: calo mục tiêu + chuỗi BMR → TDEE → điều chỉnh
class _CaloriesCard extends StatelessWidget {
  const _CaloriesCard({
    required this.goal,
    required this.result,
    required this.gender,
  });

  final Goal goal;
  final NutritionResult result;
  final Gender gender;

  @override
  Widget build(BuildContext context) {
    final badge = switch (goal) {
      Goal.loseWeight => 'Đã tính thâm hụt',
      Goal.gainWeight => 'Đã tính thặng dư',
      Goal.maintain => null,
    };
    final diff = result.calorieDifference.round();
    const chipText = TextStyle(
      fontSize: 13,
      height: 19.5 / 13,
      fontWeight: FontWeight.w600,
      color: AppColors.primaryDark,
    );
    final arrow = SvgPicture.asset('assets/icons/ic_arrow_small.svg');

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        border: Border.all(color: const Color(0xFFBBF7D0)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          // Hình quả táo mờ trang trí ở góc dưới phải
          Positioned(
            right: 0,
            bottom: 0,
            child: SvgPicture.asset('assets/icons/ic_apple_watermark.svg'),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SvgPicture.asset('assets/icons/ic_flame.svg'),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Calo mục tiêu · ${_goalLabel(goal)}',
                        style: const TextStyle(
                          fontSize: 14,
                          height: 21 / 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                    if (badge != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xCCFFFFFF),
                          borderRadius: BorderRadius.circular(9999),
                        ),
                        child: Text(
                          badge,
                          style: const TextStyle(
                            fontSize: 11,
                            height: 16.5 / 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 40,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        _kcal(result.targetKcal),
                        style: const TextStyle(
                          fontSize: 36,
                          height: 1,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.9,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'kcal/ngày',
                        style: TextStyle(
                          fontSize: 16,
                          height: 24 / 16,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('BMR ${_kcal(result.bmr)}', style: chipText),
                      const SizedBox(width: 6),
                      arrow,
                      const SizedBox(width: 6),
                      Text('TDEE ${_kcal(result.tdee)}', style: chipText),
                      if (diff != 0) ...[
                        const SizedBox(width: 6),
                        arrow,
                        const SizedBox(width: 6),
                        Text(
                          diff > 0
                              ? '+${_int.format(diff)}'
                              : '−${_int.format(-diff)}',
                          style: chipText.copyWith(
                            fontWeight: FontWeight.w700,
                            color: _amber,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (result.floorApplied) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Đã nâng lên mức tối thiểu an toàn '
                    '${gender == Gender.female ? '1.200' : '1.500'} kcal',
                    style: const TextStyle(
                      fontSize: 12,
                      height: 18 / 12,
                      color: _amber,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Khung thẻ trắng dùng cho thẻ macro và thẻ chia bữa
class _WhiteCard extends StatelessWidget {
  const _WhiteCard({
    required this.title,
    required this.trailing,
    required this.child,
  });

  final String title;
  final String trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.outline),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 22.5 / 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                trailing,
                style: const TextStyle(
                  fontSize: 12,
                  height: 18 / 12,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          child,
        ],
      ),
    );
  }
}

/// Donut tỷ lệ macro + 3 dòng chú thích (chấm màu + tên, không chỉ dựa vào màu)
class _MacroCard extends StatelessWidget {
  const _MacroCard({required this.goal, required this.result});

  final Goal goal;
  final NutritionResult result;

  @override
  Widget build(BuildContext context) {
    final rows = [
      ('Protein', result.proteinG, result.proteinPct, _proteinColor),
      ('Carbs', result.carbsG, result.carbsPct, _carbsColor),
      ('Fat', result.fatG, result.fatPct, _fatColor),
    ];
    return _WhiteCard(
      title: 'Tỷ lệ macro khuyến nghị',
      trailing: _goalLabel(goal),
      child: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Row(
          children: [
            SizedBox(
              width: 88,
              height: 88,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      startDegreeOffset:
                          -90, // bắt đầu từ 12 giờ, chạy theo chiều kim đồng hồ
                      sectionsSpace: 0,
                      centerSpaceRadius: 26,
                      sections: [
                        for (final r in rows)
                          PieChartSectionData(
                            value: r.$3,
                            color: r.$4,
                            radius: 12,
                            showTitle: false,
                          ),
                      ],
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _kcal(result.targetKcal),
                        style: const TextStyle(
                          fontSize: 12,
                          height: 16 / 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Text(
                        'kcal',
                        style: TextStyle(
                          fontSize: 9,
                          height: 12 / 9,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                children: [
                  for (final (i, r) in rows.indexed) ...[
                    if (i > 0) const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: r.$4,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            r.$1,
                            style: const TextStyle(
                              fontSize: 14,
                              height: 20 / 14,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: '${_int.format(r.$2.round())} g ',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              TextSpan(
                                text: '· ${r.$3.round()}%',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                          style: const TextStyle(height: 20 / 14),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Biểu đồ cột 4 bữa: số kcal trên đầu cột, tên bữa + % dưới đường đáy
class _MealCard extends StatelessWidget {
  const _MealCard({required this.result});

  final NutritionResult result;

  static const _meals = [
    ('Sáng', 'assets/icons/ic_sunrise.svg'),
    ('Trưa', 'assets/icons/ic_sun.svg'),
    ('Tối', 'assets/icons/ic_moon.svg'),
    ('Phụ', 'assets/icons/ic_snack.svg'),
  ];
  static const _maxBarHeight = 72.0; // cột cao nhất (bữa trưa) theo Figma

  @override
  Widget build(BuildContext context) {
    final kcal = result.mealKcal;
    final maxKcal = kcal.reduce((a, b) => a > b ? a : b);
    return _WhiteCard(
      title: 'Phân bổ calo theo bữa',
      trailing: '4 bữa/ngày',
      child: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 94,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (final k in kcal)
                      SizedBox(
                        width: 40,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _int.format(k),
                              style: const TextStyle(
                                fontSize: 13,
                                height: 1,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              width: 40,
                              height: maxKcal == 0
                                  ? 0
                                  : (k / maxKcal * _maxBarHeight)
                                        .roundToDouble(),
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1, thickness: 1, color: AppColors.outline),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (final (i, m) in _meals.indexed)
                    SizedBox(
                      width: 40,
                      child: Column(
                        children: [
                          // Tên bữa + icon rộng hơn cột 40 một chút: cho phép tràn ra hai bên
                          SizedBox(
                            height: 19.5,
                            child: OverflowBox(
                              maxWidth: double.infinity,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SvgPicture.asset(m.$2),
                                  const SizedBox(width: 2),
                                  Text(
                                    m.$1,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      height: 19.5 / 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            '${NutritionCalculator.mealShares[i]}%',
                            style: const TextStyle(
                              fontSize: 11,
                              height: 16.5 / 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
