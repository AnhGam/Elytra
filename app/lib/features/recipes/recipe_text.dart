// Hàm chuẩn hóa chữ tiếng Việt dùng cho tìm kiếm công thức (thuần Dart).

// 12 nguyên âm × 5 thanh (huyền, sắc, hỏi, ngã, nặng), dạng thường, dựng sẵn.
const Map<String, String> _toneTable = {
  'a': 'àáảãạ',
  'ă': 'ằắẳẵặ',
  'â': 'ầấẩẫậ',
  'e': 'èéẻẽẹ',
  'ê': 'ềếểễệ',
  'i': 'ìíỉĩị',
  'o': 'òóỏõọ',
  'ô': 'ồốổỗộ',
  'ơ': 'ờớởỡợ',
  'u': 'ùúủũụ',
  'ư': 'ừứửữự',
  'y': 'ỳýỷỹỵ',
};

// Thứ tự dấu thanh tương ứng với các cột của bảng trên.
const List<int> _toneMarks = [0x0300, 0x0301, 0x0309, 0x0303, 0x0323];
const int _breve = 0x0306; // dấu trăng
const int _circumflex = 0x0302; // dấu mũ
const int _horn = 0x031B; // dấu móc

// Nguyên âm cơ sở + dấu phụ -> nguyên âm có dấu phụ.
const Map<String, Map<int, String>> _modifierTable = {
  'a': {_breve: 'ă', _circumflex: 'â'},
  'e': {_circumflex: 'ê'},
  'o': {_circumflex: 'ô', _horn: 'ơ'},
  'u': {_horn: 'ư'},
};

// Ký tự có dấu dựng sẵn (thường) -> chữ không dấu.
final Map<String, String> _plainMap = () {
  final m = <String, String>{'đ': 'd'};
  _toneTable.forEach((base, tones) {
    final plain = _plainOf(base);
    m[base] = plain;
    for (final r in tones.runes) {
      m[String.fromCharCode(r)] = plain;
    }
  });
  return m;
}();

String _plainOf(String vowel) {
  switch (vowel) {
    case 'ă':
    case 'â':
      return 'a';
    case 'ê':
      return 'e';
    case 'ô':
    case 'ơ':
      return 'o';
    case 'ư':
      return 'u';
    default:
      return vowel;
  }
}

bool _isCombining(int r) => r >= 0x0300 && r <= 0x036F;

/// Thường hóa, bỏ dấu, đ -> d; giữ khoảng trắng và dấu câu.
String removeDiacritics(String s) {
  final sb = StringBuffer();
  for (final r in s.toLowerCase().runes) {
    if (_isCombining(r)) continue;
    final ch = String.fromCharCode(r);
    sb.write(_plainMap[ch] ?? ch);
  }
  return sb.toString();
}

/// Đưa chữ tiếng Việt dạng tổ hợp (NFD) hoặc nửa tổ hợp về dạng dựng sẵn (NFC).
/// Tổ hợp không có trong bảng thì giữ nguyên.
String composeVietnamese(String s) {
  final runes = s.runes.toList();
  final sb = StringBuffer();
  var i = 0;
  while (i < runes.length) {
    final base = String.fromCharCode(runes[i]);
    final lower = base.toLowerCase();
    var j = i + 1;
    while (j < runes.length && _isCombining(runes[j])) {
      j++;
    }
    final marks = runes.sublist(i + 1, j);
    final composed = marks.isEmpty || !_toneTable.containsKey(lower)
        ? null
        : _compose(lower, marks);
    if (composed == null) {
      sb.write(String.fromCharCodes(runes.sublist(i, j)));
    } else {
      sb.write(base != lower ? composed.toUpperCase() : composed);
    }
    i = j;
  }
  return sb.toString();
}

// Ghép nguyên âm thường với các dấu; trả về null nếu không có trong bảng.
String? _compose(String vowel, List<int> marks) {
  int? modifier;
  int? tone;
  for (final m in marks) {
    final idx = _toneMarks.indexOf(m);
    if (idx >= 0) {
      if (tone != null) return null;
      tone = idx;
    } else if (m == _breve || m == _circumflex || m == _horn) {
      if (modifier != null) return null;
      modifier = m;
    } else {
      return null;
    }
  }
  var v = vowel;
  if (modifier != null) {
    final next = _modifierTable[vowel]?[modifier];
    if (next == null) return null;
    v = next;
  }
  if (tone == null) return v;
  final row = _toneTable[v];
  if (row == null) return null;
  return String.fromCharCode(row.runes.elementAt(tone));
}

/// Thường hóa, chuẩn NFC, tách theo mọi ký tự không phải chữ/số; bỏ phần rỗng.
List<String> wordsOf(String s) {
  final text = composeVietnamese(s.toLowerCase());
  return text
      .split(RegExp(r'[^\p{L}\p{M}\p{N}]+', unicode: true))
      .where((w) => w.isNotEmpty)
      .toList();
}

/// Chuỗi dùng làm slug: không dấu, nối bằng '-'.
String slugify(String s) {
  return removeDiacritics(s)
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
}

/// Cắt khoảng trắng, gộp khoảng trắng liên tiếp và viết hoa chữ đầu.
String displayTitle(String s) {
  final t = s.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (t.isEmpty) return '';
  final first = String.fromCharCode(t.runes.first);
  return first.toUpperCase() + t.substring(first.length);
}

/// Định dạng số phút thành "40 phút", "1 giờ", "3 giờ 20 phút".
String formatDuration(int minutes) {
  final h = minutes ~/ 60;
  final m = minutes % 60;
  if (h == 0) return '$m phút';
  if (m == 0) return '$h giờ';
  return '$h giờ $m phút';
}
