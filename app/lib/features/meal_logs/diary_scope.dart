import 'package:flutter/widgets.dart';

import 'diary_store.dart';

/// Chia sẻ [DiaryStore] cho cây widget bên dưới.
class DiaryScope extends InheritedNotifier<DiaryStore> {
  const DiaryScope({super.key, required DiaryStore store, required super.child})
      : super(notifier: store);

  /// Như [of] nhưng trả null khi không có DiaryScope phía trên.
  static DiaryStore? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<DiaryScope>()?.notifier;

  static DiaryStore of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<DiaryScope>();
    if (scope == null) {
      throw FlutterError('DiaryScope.of() được gọi khi không có DiaryScope phía trên.');
    }
    return scope.notifier!;
  }
}
