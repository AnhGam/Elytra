/// Định dạng ngày kiểu Việt Nam, không phụ thuộc dữ liệu locale của intl
/// (DateFormat 'vi' cần initializeDateFormatting). Chỉ đọc year/month/day/weekday.
library;

const _long = ['Thứ Hai', 'Thứ Ba', 'Thứ Tư', 'Thứ Năm', 'Thứ Sáu', 'Thứ Bảy', 'Chủ Nhật'];
const _short = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

/// "Thứ Ba", "Chủ Nhật".
String weekdayLong(DateTime d) => _long[d.weekday - 1];

/// "T3", "CN".
String weekdayShort(DateTime d) => _short[d.weekday - 1];

/// "Thứ Ba, 10 tháng 11".
String longDateLabel(DateTime d) => '${weekdayLong(d)}, ${d.day} tháng ${d.month}';
