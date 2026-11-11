import '../../core/uuid.dart';
import 'meal_log_models.dart';
import 'meal_log_repository.dart';

/// Khoá idempotency (`client_request_id`) gắn với nội dung request.
/// Gửi lại y nguyên thì giữ khoá cũ; nội dung khác thì sinh khoá mới.
class RequestKeys {
  RequestKeys({this._newId = uuidV4});

  final String Function() _newId;
  LogRequest? _req;
  String? _key;
  bool _networkError = false;

  /// Đã có ít nhất một lần lỗi mạng kể từ lần thành công / xoá cờ gần nhất.
  bool get hadNetworkError => _networkError;

  String keyFor(LogRequest req) {
    final k = _key;
    if (k != null && _req == req) return k;
    _req = req;
    return _key = _newId();
  }

  /// Gửi thành công: bỏ cặp (nội dung, khoá); xoá luôn cờ lỗi mạng.
  void succeeded() => reset();

  /// Bỏ khoá hiện tại (thành công, hoặc server báo khoá đã dùng cho nội dung khác:
  /// `IDEMPOTENCY_CONFLICT`); lần gửi sau sinh khoá mới.
  void reset() {
    _req = null;
    _key = null;
    _networkError = false;
  }

  /// Lỗi [e] có phải server báo trùng khoá với nội dung khác không.
  static bool isConflict(Object e) =>
      e is MealLogFailed && e.code == 'IDEMPOTENCY_CONFLICT';

  void markNetworkError() => _networkError = true;

  /// Chỉ xoá cờ lỗi mạng (sau khi đã làm mới ngày); khoá vẫn giữ để gửi lại
  /// y nguyên không ghi trùng nếu request đầu thực ra đã tới server.
  void clearNetworkError() => _networkError = false;
}
