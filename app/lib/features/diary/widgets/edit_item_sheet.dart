import 'package:flutter/material.dart';

import 'package:elytra/core/meal_time.dart';
import 'package:elytra/core/theme.dart';
import 'package:elytra/features/meal_logs/budget_view.dart';
import 'package:elytra/features/meal_logs/diary_store.dart';
import 'package:elytra/features/meal_logs/meal_log_models.dart';
import 'package:elytra/features/meal_logs/meal_log_repository.dart';
import 'package:elytra/features/meal_logs/portion_math.dart';
import 'package:elytra/features/meal_logs/widgets/portion_inputs.dart';

const kTooOldNote = 'Chỉ sửa được món trong 30 ngày gần nhất';

/// Mở sheet sửa lượng / xoá một món của ngày [date].
Future<void> showEditItemSheet(
  BuildContext context, {
  required DiaryStore store,
  required MealLogItem item,
  required MealType meal,
  required String date,
  required String dayLabel,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    // Như PortionSheet: khoá đóng khi đang lưu/xoá (PopScope), nên không cho kéo
    enableDrag: false,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => EditItemSheet(
      store: store,
      item: item,
      meal: meal,
      date: date,
      dayLabel: dayLabel,
    ),
  );
}

/// Sheet sửa món (`PATCH` chỉ đổi lượng) và nút "Xoá" (§7.3, diary-02).
class EditItemSheet extends StatefulWidget {
  const EditItemSheet({
    super.key,
    required this.store,
    required this.item,
    required this.meal,
    required this.date,
    required this.dayLabel,
  });

  final DiaryStore store;
  final MealLogItem item;
  final MealType meal;
  final String date;

  /// "Hôm nay" hoặc "T2, 9/11".
  final String dayLabel;

  @override
  State<EditItemSheet> createState() => _EditItemSheetState();
}

class _EditItemSheetState extends State<EditItemSheet> {
  MealLogItem get _item => widget.item;
  late double _servings = _item.servings ?? 1;
  late final _gram = TextEditingController(
    text: (_item.amountG ?? 100).round().toString(),
  );
  bool _busy = false;
  bool _deleting = false; // đang xoá (để nút Lưu không ghi "Đang lưu…")
  String? _error;

  @override
  void dispose() {
    _gram.dispose();
    super.dispose();
  }

  int? get _grams => parseGram(_gram.text);

  /// Dinh dưỡng của lượng mới, suy từ snapshot của món (tỉ lệ theo lượng cũ).
  Macros? get _preview {
    final m = _item.macros;
    if (_item.byServings) {
      final old = _item.servings ?? 1;
      return old <= 0 ? null : m.scale(_servings / old);
    }
    final g = _grams;
    final old = _item.amountG;
    if (g == null || old == null || old <= 0) return null;
    return m.scale(g / old);
  }

  bool get _changed => _item.byServings
      ? _servings != (_item.servings ?? 1)
      : _grams != null && _grams != _item.amountG?.round();

  String? _afterSave(Macros? p) {
    final day = widget.store.day(widget.date).log;
    if (p == null || day == null) return null;
    final left = day.budget.remaining.kcal + _item.macros.kcal - p.kcal;
    return left < 0
        ? 'Sau khi lưu: cả ngày vượt ${formatKcal(-left)} kcal'
        : 'Sau khi lưu: cả ngày còn ${formatKcal(left)} kcal';
  }

  String _errorText(Object e) => switch (e) {
    MealLogTooOld() => kTooOldNote,
    MealLogOffline() => 'Không có mạng. Thử lại',
    MealLogItemNotFound() => 'Món này không còn trong nhật ký.',
    _ => 'Không lưu được. Thử lại sau.',
  };

  Future<void> _run(
    Future<void> Function() action, {
    bool deleting = false,
  }) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _deleting = deleting;
      _error = null;
    });
    try {
      await action();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (e is MealLogItemNotFound) {
        // Món đã bị xoá ở nơi khác: tải lại ngày để danh sách khớp server
        await widget.store.refreshDay(widget.date).catchError((Object _) {});
      }
      if (mounted) {
        setState(() {
          _busy = false;
          _error = _errorText(e);
        });
      }
    }
  }

  void _save() => _run(
    () => _item.byServings
        ? widget.store.update(_item, servings: _servings, date: widget.date)
        : widget.store.update(_item, amountG: _grams, date: widget.date),
  );

  void _delete() =>
      _run(() => widget.store.delete(_item, date: widget.date), deleting: true);

  @override
  Widget build(BuildContext context) {
    final preview = _preview;
    final canSave = !_busy && _changed && preview != null;
    return PopScope(
      canPop: !_busy,
      child: PortionSheetFrame(
        title: _item.name,
        subtitle:
            'Bữa ${widget.meal.labelVi} · ${widget.dayLabel} · '
            'đang ghi ${_item.byServings ? formatServings(_item.servings ?? 1) : '${formatGram(_item.amountG ?? 0)} g'}',
        onClose: _busy ? null : () => Navigator.of(context).pop(),
        content: [
          if (_item.byServings)
            ServingsStepper(
              value: _servings,
              enabled: !_busy,
              onChanged: (v) => setState(() => _servings = v),
            )
          else
            GramInput(
              controller: _gram,
              enabled: !_busy,
              onChanged: () => setState(() {}),
            ),
          const SizedBox(height: 16),
          MacroPreviewBox(preview: preview, note: _afterSave(preview)),
          const SizedBox(height: 12),
          const Text(
            'Muốn chuyển món sang bữa khác: xoá rồi thêm lại ở bữa đó.',
            style: TextStyle(
              fontSize: 13,
              height: 18 / 13,
              color: AppColors.textMuted,
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
        footer: Row(
          children: [
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : _delete,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.onErrorContainer,
                    side: const BorderSide(color: AppColors.outlineStrong),
                    shape: const StadiumBorder(),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  icon: const Icon(Icons.delete_outline),
                  label: Text(_busy && _deleting ? 'Đang xoá…' : 'Xoá'),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: canSave ? _save : null,
                  style: primarySheetButtonStyle(),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      _busy && !_deleting ? 'Đang lưu…' : 'Lưu thay đổi',
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
