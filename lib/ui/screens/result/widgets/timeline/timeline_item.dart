import 'package:flutter/material.dart';
import 'package:parfume_app/core/strings/app_strings.dart';
import 'package:parfume_app/ui/theme/app_colors.dart';
import 'package:parfume_app/ui/theme/app_sizes.dart';
import 'package:parfume_app/ui/theme/app_text_styles.dart';

import '../../models/timeline_message.dart';

/// A single step in the result flow timeline.
///
/// Renders the step icon, message text, and timestamp. An animated vertical
/// connector is drawn below the icon for all steps except the last one.
///
/// Active steps show a [CircularProgressIndicator] and a radial pulse glow.
/// Completed steps show a check icon; error steps show an error icon.
class TimelineItem extends StatefulWidget {
  const TimelineItem({
    super.key,
    required this.message,
    required this.isLast,
    required this.strings,
  });

  final TimelineMessage message;
  final bool isLast;
  final AppStrings strings;

  @override
  State<TimelineItem> createState() => _TimelineItemState();
}

class _TimelineItemState extends State<TimelineItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );
    if (widget.message.status == TimelineMessageStatus.active) {
      _pulseController.repeat();
    }
  }

  @override
  void didUpdateWidget(TimelineItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.message.status == TimelineMessageStatus.active) {
      if (!_pulseController.isAnimating) _pulseController.repeat();
    } else {
      _pulseController.stop();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 10 * (1 - value)),
          child: child,
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon + connector column — stretches to match content height.
            SizedBox(
              width: AppSizes.timelineIconSize + 8,
              child: Column(
                children: [
                  _buildIcon(color),
                  if (!widget.isLast)
                    Expanded(
                      child: Center(
                        child: Container(
                          width: AppSizes.timelineConnectorWidth,
                          color: color.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(width: AppSizes.spacingS),

            // Message text + timestamp in a row.
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(
                  bottom: AppSizes.spacingM,
                  top: AppSizes.spacingXS,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Message text.
                    Expanded(
                      child: Text(
                        message.resolve(widget.strings),
                        style: AppTextStyles.body.copyWith(
                          fontSize: AppSizes.fontBodyLarge,
                          height: 1.3,
                          fontWeight: widget.message.status ==
                                  TimelineMessageStatus.active
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: color,
                        ),
                      ),
                    ),

                    const SizedBox(width: AppSizes.spacingS),

                    // Timestamp — right-aligned.
                    Text(
                      _formatTime(widget.message.timestamp),
                      style: AppTextStyles.hint.copyWith(
                        fontSize: AppSizes.fontHint * 2,
                        color: color.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon(Color color) {
    if (widget.message.status == TimelineMessageStatus.active) {
      return SizedBox(
        width: AppSizes.timelineIconSize,
        height: AppSizes.timelineIconSize,
        child: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: AppSizes.timelineIconSize *
                      (1.0 + _pulseAnimation.value * 0.6),
                  height: AppSizes.timelineIconSize *
                      (1.0 + _pulseAnimation.value * 0.6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(
                      alpha: 0.15 * (1.0 - _pulseAnimation.value),
                    ),
                  ),
                ),
                SizedBox(
                  width: AppSizes.timelineIconSize,
                  height: AppSizes.timelineIconSize,
                  child: CircularProgressIndicator(
                    strokeWidth: 3.5,
                    color: color,
                  ),
                ),
              ],
            );
          },
        ),
      );
    }

    return Icon(_statusIcon, color: color, size: AppSizes.timelineIconSize);
  }

  Color get _statusColor => switch (widget.message.status) {
        TimelineMessageStatus.pending => AppColors.textSecondary,
        TimelineMessageStatus.active => AppColors.primary,
        TimelineMessageStatus.completed => AppColors.success,
        TimelineMessageStatus.error => AppColors.error,
      };

  IconData get _statusIcon => switch (widget.message.status) {
        TimelineMessageStatus.pending => Icons.radio_button_unchecked,
        TimelineMessageStatus.active => Icons.sync,
        TimelineMessageStatus.completed => Icons.check_circle,
        TimelineMessageStatus.error => Icons.error,
      };

  String _formatTime(DateTime time) =>
      '${time.hour.toString().padLeft(2, '0')}:'
      '${time.minute.toString().padLeft(2, '0')}';

  TimelineMessage get message => widget.message;
}