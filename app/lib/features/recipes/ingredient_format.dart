import 'package:intl/intl.dart';

import 'recipe.dart';
import 'recipe_text.dart';

/// Một dòng nguyên liệu đã định dạng để hiển thị.
class IngredientLine {
  const IngredientLine({
    required this.name,
    this.amountText,
    this.gramText,
    this.note,
  });

  final String name;
  final String? amountText;
  final String? gramText;
  final String? note;
}

// Đơn vị đếm được: có kèm dòng quy đổi ra gam.
const Set<String> _countableUnits = {
  'củ', 'quả', 'trái', 'cây', 'miếng', 'chén', 'bát', 'bó', 'nhánh',
  'tép', 'lát', 'con', 'cái', 'lá', 'khúc', 'gói', 'hộp',
};

// Đơn vị không có lượng cụ thể: chỉ hiện ghi chú.
const Set<String> _noteOnlyUnits = {'phần', 'ít'};

/// Định dạng số lượng kiểu Việt Nam; phần lẻ 0,5 hiện thành "½".
String formatAmount(double v) {
  final r = (v * 10).round() / 10;
  final whole = r.truncate();
  final frac = ((r - whole) * 10).round();
  if (frac == 5) {
    return whole == 0 ? '½' : '$whole½';
  }
  return NumberFormat('#,##0.#', 'vi').format(r);
}

// Chuẩn hóa đơn vị: so khớp không phân biệt hoa thường; đơn vị lạ giữ nguyên chữ.
String _normalizeUnit(String unit) {
  final u = unit.trim().toLowerCase();
  if (u == 'muỗng cà' || u == 'muỗng cafe') return 'muỗng cà phê';
  if (u == 'gram') return 'g';
  if (_countableUnits.contains(u) ||
      _noteOnlyUnits.contains(u) ||
      u == 'g' ||
      u == 'kg' ||
      u == 'ml' ||
      u == 'lít' ||
      u.startsWith('muỗng')) {
    return u;
  }
  return unit.trim();
}

String _capitalize(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

// Ghi chú lấy từ raw_text; rỗng nghĩa là "Tùy thích".
String _noteOf(RecipeIngredient row) {
  final raw = row.rawText;
  final nameSlug = slugify(row.nameRaw);
  final i = raw.indexOf(':');
  if (i >= 0) {
    if (slugify(raw.substring(0, i)) == nameSlug) {
      return raw.substring(i + 1).trim();
    }
    return raw.trim();
  }
  return slugify(raw) == nameSlug ? '' : raw.trim();
}

/// Quyết định chữ hiển thị của một nguyên liệu theo số khẩu phần [factor].
IngredientLine formatIngredient(RecipeIngredient row, double factor) {
  final name = _capitalize(row.nameRaw);
  final amount = row.amount;
  final unit = row.unit == null ? null : _normalizeUnit(row.unit!);

  if (amount == null || (unit != null && _noteOnlyUnits.contains(unit))) {
    final note = _noteOf(row);
    return IngredientLine(name: name, note: note.isEmpty ? 'Tùy thích' : note);
  }

  final number = formatAmount(amount * factor);
  final amountText = unit == null ? number : '$number $unit';
  String? gramText;
  if (unit != null && _countableUnits.contains(unit) && row.amountG > 0) {
    gramText = '${NumberFormat('#,##0', 'vi').format(row.amountG * factor)} g';
  }
  return IngredientLine(name: name, amountText: amountText, gramText: gramText);
}
