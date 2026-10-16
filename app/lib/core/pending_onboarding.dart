import 'package:flutter/foundation.dart';

import 'package:elytra/features/onboarding/body_info.dart';

/// Thể trạng đã khai báo nhưng chưa lưu lên server.
/// Giữ từ lúc bấm "Lưu kết quả & tạo tài khoản" tới khi ProfileGate lưu xong.
final pendingBodyInfo = ValueNotifier<BodyInfo?>(null);
