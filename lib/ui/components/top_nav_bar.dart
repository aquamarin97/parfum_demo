import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class TopNavBar extends StatelessWidget {
  const TopNavBar({
    super.key,
    required this.title,
    required this.backLabel,
    required this.cancelLabel,
    required this.onBack,
    required this.onCancel,
    this.backEnabled = true,
    this.showBack = true,
    this.showCancel = true,
    this.height,
  });

  final String title;
  final String backLabel;
  final String cancelLabel;
  final VoidCallback onBack;
  final VoidCallback onCancel;
  final bool backEnabled;
  final bool showBack;
  final bool showCancel;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final titleStyle = AppTextStyles.topBarTitle;
    final actionStyle = AppTextStyles.topBarAction;
    final effectiveHeight = height ?? MediaQuery.sizeOf(context).height * 0.05;

    return Material(
      color: AppColors.surface,
      child: Container(
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.border)),
          boxShadow: [
            BoxShadow(
              blurRadius: 16,
              offset: Offset(0, 6),
              color: Color(0x14000000),
            ),
          ],
        ),
        child: SafeArea(
          bottom: false,
          child: SizedBox(
            height: effectiveHeight,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 100),
              child: Row(
                children: [
                  /// BACK
                  ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 180),
                    child: showBack
                        ? TextButton(
                            onPressed: backEnabled ? onBack : null,
                            style: TextButton.styleFrom(
                              alignment:
                                  Alignment.center, // ✅ GERÇEK merkezleme
                              minimumSize: const Size(
                                180,
                                72,
                              ), // ✅ dokunmatik alan
                              foregroundColor: backEnabled
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 30,
                                vertical: 15,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              textStyle: actionStyle,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min, // ✅ güvenli
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.chevron_left_rounded,
                                  size: 64, // ⚠️ 100 yerine dengeli
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  backLabel,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),

                  /// TITLE
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: titleStyle,
                    ),
                  ),

                  /// CANCEL
                  ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 140),
                    child: showCancel
                        ? Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: onCancel,
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.error,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 30,
                                  vertical: 15,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                textStyle: actionStyle,
                              ),
                              child: Text(
                                cancelLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
