import 'package:flutter/material.dart';
import 'package:parfume_app/core/strings/app_strings.dart';
import 'package:parfume_app/ui/theme/app_colors.dart';
import 'package:parfume_app/ui/theme/app_sizes.dart';

import '../../models/timeline_message.dart';
import 'timeline_item.dart';

/// Scrollable container that displays the result flow timeline.
///
/// Expands smoothly as new steps are added via [AnimatedSize].
/// Each step is rendered by [TimelineItem]; the last item's connector
/// line is hidden via the [TimelineItem.isLast] flag.
class TimelineContainer extends StatefulWidget {
  const TimelineContainer({
    super.key,
    required this.messages,
    required this.strings,
  });

  final List<TimelineMessage> messages;
  final AppStrings strings;

  @override
  State<TimelineContainer> createState() => _TimelineContainerState();
}

class _TimelineContainerState extends State<TimelineContainer>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();

  @override
  void didUpdateWidget(TimelineContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.messages.length != oldWidget.messages.length) {
      // Scroll to bottom after the new item has been laid out.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.messages.isEmpty) return const SizedBox.shrink();

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      alignment: Alignment.topCenter,
      child: Container(
        constraints: const BoxConstraints(
          maxHeight: AppSizes.timelineItemMaxHeight,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(AppSizes.radiusL),
          border: Border.all(
            color: AppColors.border.withValues(alpha: 0.6),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppSizes.radiusL),
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.all(AppSizes.spacingS),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int i = 0; i < widget.messages.length; i++)
                  TimelineItem(
                    message: widget.messages[i],
                    isLast: i == widget.messages.length - 1,
                    strings: widget.strings,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}