import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:elytra/main.dart';

/// Mọi lệnh gọi Supabase Auth của app đi qua đây.
/// Màn hình chỉ gọi các hàm này rồi hiện lỗi; việc chuyển màn do router lo.
class AuthRepository {
  Future<void> signIn(String email, String password) =>
      supabase.auth.signInWithPassword(email: email.trim(), password: password);

  /// Tạo tài khoản. Trả về `true` nếu người dùng phải xác nhận email trước
  /// khi đăng nhập (khi bật "Confirm email" trên Supabase).
  /// Lưu thời điểm đồng ý điều khoản vào user_metadata (ô tick ở màn Đăng ký).
  Future<bool> signUp(String email, String password) async {
    final res = await supabase.auth.signUp(
      email: email.trim(),
      password: password,
      data: {'terms_accepted_at': DateTime.now().toUtc().toIso8601String()},
    );
    // Khi bật xác nhận email, Supabase không báo "email đã tồn tại" mà trả về
    // một user có danh sách identities rỗng
    if (res.user?.identities?.isEmpty ?? false) {
      throw AuthException('User already registered');
    }
    return res.session == null;
  }

  Future<void> signOut() => supabase.auth.signOut();

  // Quên mật khẩu (4.6)
  Future<void> sendResetEmail(String email) => supabase.auth.resetPasswordForEmail(
        email.trim(),
        redirectTo: 'vn.edu.uit.elytra://reset-callback',
      );

  Future<void> updatePassword(String password) =>
      supabase.auth.updateUser(UserAttributes(password: password));
}

final authRepo = AuthRepository();

/// Đổi lỗi của Supabase sang câu tiếng Việt
String authErrorMessage(Object e) {
  if (e is AuthException) {
    final m = e.message.toLowerCase();
    if (m.contains('invalid login credentials')) return 'Email hoặc mật khẩu không đúng.';
    if (m.contains('already registered')) return 'Email này đã có tài khoản. Hãy đăng nhập.';
    if (m.contains('email not confirmed')) return 'Bạn chưa xác nhận email. Hãy kiểm tra hộp thư.';
    if (m.contains('security purposes') || m.contains('rate limit')) {
      return 'Vui lòng chờ 1 phút rồi thử lại.';
    }
    if (m.contains('different from the old')) return 'Mật khẩu mới phải khác mật khẩu cũ.';
    if (m.contains('password')) return 'Mật khẩu chưa đủ mạnh (tối thiểu 8 ký tự).';
    return e.message;
  }
  return 'Không kết nối được máy chủ. Kiểm tra mạng và thử lại.';
}
