/// Tên hiển thị: bỏ khoảng trắng thừa; rỗng hoặc là email (có '@') thì null.
String? displayName(String? fullName) {
  final s = fullName?.trim();
  if (s == null || s.isEmpty || s.contains('@')) return null;
  return s;
}

/// Tên gọi ngắn: từ cuối của họ tên.
String shortName(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  return parts.last;
}

/// Lời chào theo giờ; chỉ đọc `hour` và `minute` của [t].
String greeting(DateTime t) {
  final m = t.hour * 60 + t.minute;
  if (m >= 4 * 60 && m < 11 * 60) return 'Chào buổi sáng';
  if (m >= 11 * 60 && m < 14 * 60) return 'Chào buổi trưa';
  if (m >= 14 * 60 && m < 18 * 60) return 'Chào buổi chiều';
  return 'Chào buổi tối';
}

/// Chữ cái đầu (viết hoa) của tên gọi ngắn, dùng cho avatar.
String avatarInitial(String name) {
  final s = shortName(name);
  return s.isEmpty ? '' : s.substring(0, 1).toUpperCase();
}
