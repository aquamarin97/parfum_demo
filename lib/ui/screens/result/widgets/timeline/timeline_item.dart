import 'package:flutter/material.dart';
import 'package:parfume_app/ui/theme/app_colors.dart';
import 'package:parfume_app/ui/theme/app_text_styles.dart';

import '../../models/timeline_message.dart';

class TimelineItem extends StatelessWidget {
  const TimelineItem({super.key, required this.message, required this.index});

  final TimelineMessage message;
  final int index;

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();
    final statusIcon = _getStatusIcon();

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - value)),
            child: Container(
              // ✅ Sabit yükseklik: 100px
              constraints: const BoxConstraints(minHeight: 100, maxHeight: 100),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: message.status == TimelineMessageStatus.active
                    ? statusColor.withOpacity(0.05)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: message.status == TimelineMessageStatus.active
                    ? Border.all(
                        color: statusColor.withOpacity(0.2),
                        width: 1.5,
                      )
                    : null,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // İkon
                  _buildIcon(statusColor, statusIcon),

                  const SizedBox(width: 16),

                  // Mesaj
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message.text,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.body.copyWith(
                            fontFamily: 'NotoSans',
                            fontSize: 40, // 50 → 40 (daha kompakt)
                            height: 1.2,
                            fontWeight:
                                message.status == TimelineMessageStatus.active
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Zaman damgası (opsiyonel, istemezsen kaldır)
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      fontSize: 28,
                      color: AppColors.textSecondary.withOpacity(0.6),
                      fontFamily: 'NotoSans',
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildIcon(Color color, IconData icon) {
    if (message.status == TimelineMessageStatus.active) {
      return SizedBox(
        width: 48,
        height: 48,
        child: CircularProgressIndicator(strokeWidth: 3.5, color: color),
      );
    }

    return Icon(icon, color: color, size: 48);
  }

  Color _getStatusColor() {
    switch (message.status) {
      case TimelineMessageStatus.pending:
        return AppColors.textSecondary;
      case TimelineMessageStatus.active:
        return AppColors.primary;
      case TimelineMessageStatus.completed:
        return AppColors.success;
      case TimelineMessageStatus.error:
        return AppColors.error;
    }
  }

  IconData _getStatusIcon() {
    switch (message.status) {
      case TimelineMessageStatus.pending:
        return Icons.radio_button_unchecked;
      case TimelineMessageStatus.active:
        return Icons.sync;
      case TimelineMessageStatus.completed:
        return Icons.check_circle;
      case TimelineMessageStatus.error:
        return Icons.error;
    }
  }

  String _formatTime(DateTime time) {
    return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
  }
}
