import 'package:flutter/material.dart';
import 'package:parfume_app/ui/theme/app_colors.dart';
import 'package:parfume_app/ui/theme/app_text_styles.dart';

import '../../models/timeline_message.dart';

class TimelineItem extends StatelessWidget {
  const TimelineItem({
    super.key,
    required this.message,
    required this.index,
  });

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
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  // İkon
                  _buildIcon(statusColor, statusIcon),

                  const SizedBox(width: 12),

                  // Mesaj
                  Expanded(
                    child: Text(
                      message.text,
                      style: AppTextStyles.body.copyWith(
                        fontFamily: 'NotoSans',
                        fontWeight: message.status == TimelineMessageStatus.active
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: statusColor,
                      ),
                    ),
                  ),

                  // Zaman
                  Text(
                    _formatTime(message.timestamp),
                    style: AppTextStyles.body.copyWith(
                      fontSize: 12,
                      color: AppColors.textSecondary,
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
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: color,
        ),
      );
    }

    return Icon(icon, color: color, size: 24);
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