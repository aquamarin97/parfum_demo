import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_sizes.dart';
import '../../theme/app_text_styles.dart';

/// Top navigation bar used on the survey question screen.
///
/// Displays a back button on the leading side, a centred title, and a
/// cancel button on the trailing side. Each button can be hidden via
/// [showBack] and [showCancel], and the back button can be disabled
/// (greyed out) via [backEnabled].
///
/// Height defaults to 5 % of the screen height when [height] is not provided.
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

  /// Centred title text.
  final String title;

  /// Label for the back button.
  final String backLabel;

  /// Label for the cancel button.
  final String cancelLabel;

  /// Called when the back button is tapped (only when [backEnabled] is `true`).
  final VoidCallback onBack;

  /// Called when the cancel button is tapped.
  final VoidCallback onCancel;

  /// Whether the back button is interactive. When `false` the button is
  /// rendered in a disabled style and does not respond to taps.
  final bool backEnabled;

  /// Whether to render the back button. Defaults to `true`.
  final bool showBack;

  /// Whether to render the cancel button. Defaults to `true`.
  final bool showCancel;

  /// Explicit height override. Defaults to 5 % of screen height.
  final double? height;

  @override
  Widget build(BuildContext context) {
    final effectiveHeight =
        height ?? MediaQuery.sizeOf(context).height * 0.05;

    return Material(
      color: AppColors.surface,
      child: Container(
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppColors.border),
          ),
          boxShadow: [
            BoxShadow(
              blurRadius: AppSizes.navBarShadowBlur,
              offset: Offset(0, AppSizes.navBarShadowOffsetY),
              color: AppColors.shadowLight,
            ),
          ],
        ),
        child: SafeArea(
          bottom: false,
          child: SizedBox(
            height: effectiveHeight,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.screenPaddingH,
              ),
              child: Row(
                children: [
                  // Back button.
                  ConstrainedBox(
                    constraints: const BoxConstraints(
                      minWidth: AppSizes.navBarBackMinWidth,
                    ),
                    child: showBack
                        ? TextButton(
                            onPressed: backEnabled ? onBack : null,
                            style: TextButton.styleFrom(
                              alignment: Alignment.center,
                              minimumSize: const Size(
                                AppSizes.navBarBackMinWidth,
                                AppSizes.navBarMinHeight,
                              ),
                              foregroundColor: backEnabled
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSizes.navBarPaddingH,
                                vertical: AppSizes.navBarPaddingV,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppSizes.navBarRadius,
                                ),
                              ),
                              textStyle: AppTextStyles.topBarAction,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.chevron_left_rounded,
                                  size: AppSizes.navBarIconSize,
                                ),
                                const SizedBox(width: AppSizes.spacingXS),
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

                  // Centred title.
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.topBarTitle,
                    ),
                  ),

                  // Cancel button.
                  ConstrainedBox(
                    constraints: const BoxConstraints(
                      minWidth: AppSizes.navBarCancelMinWidth,
                    ),
                    child: showCancel
                        ? Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: onCancel,
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.error,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSizes.navBarPaddingH,
                                  vertical: AppSizes.navBarPaddingV,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppSizes.navBarRadius,
                                  ),
                                ),
                                textStyle: AppTextStyles.topBarAction,
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