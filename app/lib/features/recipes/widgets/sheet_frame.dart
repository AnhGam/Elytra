import 'package:flutter/material.dart';

import 'package:elytra/core/theme.dart';

/// Mở bottom sheet bo góc trên 24, cao theo nội dung (tối đa gần toàn màn)
Future<T?> showAppSheet<T>(BuildContext context, WidgetBuilder builder) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    // Mở trên root navigator để che cả thanh tab
    useRootNavigator: true,
    useSafeArea: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: builder,
  );
}

/// Khung sheet: thanh kéo, tiêu đề + nút đóng, nội dung cuộn, footer cố định
class SheetFrame extends StatelessWidget {
  const SheetFrame({
    super.key,
    required this.title,
    required this.body,
    this.footer,
    this.scrollBody = true,
  });

  final String title;
  final Widget body;
  final Widget? footer;

  /// false khi [body] tự cuộn (vd. ListView)
  final bool scrollBody;

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Đẩy sheet lên trên bàn phím khi nhập số
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.sliderInactive,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Đóng',
                  onPressed: () => Navigator.of(context).pop(),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.surfaceVariant,
                    fixedSize: const Size(40, 40),
                  ),
                  icon: const Icon(
                    Icons.close,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: scrollBody ? SingleChildScrollView(child: body) : body,
          ),
          if (footer != null)
            DecoratedBox(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.outline)),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                  child: footer,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Tiêu đề mục trong sheet
class SheetSectionTitle extends StatelessWidget {
  const SheetSectionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }
}

/// Nút chính ở footer: nền primaryDark, chữ trắng, cao 56
ButtonStyle sheetPrimaryButtonStyle() => FilledButton.styleFrom(
  backgroundColor: AppColors.primaryDark,
  foregroundColor: AppColors.surface,
  disabledBackgroundColor: AppColors.primaryDisabled,
  disabledForegroundColor: AppColors.surface,
  minimumSize: const Size.fromHeight(56),
  shape: const StadiumBorder(),
  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
);
