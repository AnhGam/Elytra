import '../../core/uuid.dart';
import 'meal_log_models.dart';

/// Khoá idempotency (`client_request_id`) gắn với nội dung request.
/// Gửi lại y nguyên thì giữ khoá cũ; nội dung khác thì sinh khoá mới.
class RequestKeys {
  RequestKeys({this._newId = uuidV4});

  final String Function() _newId;
  LogRequest? _req;
  String? _key;
  bool _networkError = false;

  /// Đã có ít nhất một lần lỗi mạng kể từ lần thành công / reset gần nhất.
  bool get hadNetworkError => _networkError;

  String keyFor(LogRequest req) {
    final k = _key;
    if (k != null && _req == req) return k;
    _req = req;
    return _key = _newId();
  }

  /// Gửi thành công: bỏ cặp (nội dung, khoá) và cờ lỗi mạng.
  void succeeded() => reset();

  void markNetworkError() => _networkError = true;

  /// Về trạng thái ban đầu (vd. đóng sheet sau khi đã làm mới ngày).
  void reset() {
    _req = null;
    _key = null;
    _networkError = false;
  }
}
