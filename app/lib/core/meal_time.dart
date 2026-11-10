/// Bữa ăn theo giờ Việt Nam. Hàm thuần nhận DateTime làm tham số;
/// "bây giờ" chỉ lấy từ [vnNow] (một nơi duy nhất, không dùng toLocal()).
enum MealType {
  breakfast,
  lunch,
  dinner,
  snack;

  /// Giá trị gửi lên API (POST /meal-logs).
  String get apiValue => name;

  /// Nhãn tiếng Việt: "bữa sáng", "bữa trưa"...
  String get labelVi => switch (this) {
        MealType.breakfast => 'sáng',
        MealType.lunch => 'trưa',
        MealType.dinner => 'tối',
        MealType.snack => 'phụ',
      };

  /// Tỉ lệ % năng lượng mục tiêu ngày dành cho bữa này.
  int get sharePct => switch (this) {
        MealType.breakfast => 25,
        MealType.lunch => 35,
        MealType.dinner => 30,
        MealType.snack => 10,
      };
}

/// Giờ hiện tại theo Việt Nam (UTC+7), không phụ thuộc múi giờ máy.
DateTime vnNow() => DateTime.now().toUtc().add(const Duration(hours: 7));

/// Xác định bữa theo giờ trong ngày; chỉ đọc `hour` và `minute` của [t].
MealType mealTypeAt(DateTime t) {
  final minutes = t.hour * 60 + t.minute;
  if (minutes >= 4 * 60 && minutes < 10 * 60 + 30) return MealType.breakfast;
  if (minutes >= 10 * 60 + 30 && minutes < 14 * 60 + 30) return MealType.lunch;
  if (minutes >= 17 * 60 && minutes < 21 * 60 + 30) return MealType.dinner;
  return MealType.snack;
}

/// Ngân sách kcal của bữa; null nếu chưa có mục tiêu hợp lệ.
int? mealBudgetKcal(double? targetKcal, MealType m) {
  if (targetKcal == null || targetKcal <= 0) return null;
  return (targetKcal * m.sharePct / 100).round();
}

/// Ngày dạng YYYY-MM-DD từ year/month/day của [t].
String isoDate(DateTime t) =>
    '${t.year.toString().padLeft(4, '0')}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';
