import 'package:flutter/material.dart';
import 'package:parfume_app/ui/theme/app_colors.dart';

import '../../models/timeline_message.dart';
import 'timeline_item.dart';

class TimelineContainer extends StatefulWidget {
  const TimelineContainer({super.key, required this.messages});

  final List<TimelineMessage> messages;

  @override
  State<TimelineContainer> createState() => _TimelineContainerState();
}

class _TimelineContainerState extends State<TimelineContainer> {
  final ScrollController _scrollController = ScrollController();

  @override
  void didUpdateWidget(TimelineContainer oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.messages.length != oldWidget.messages.length) {
      // Yeni mesaj eklendi, scroll down
      Future.delayed(const Duration(milliseconds: 100), () {
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

    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withOpacity(0.3)),
      ),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: widget.messages.length,
        itemBuilder: (context, index) {
          return TimelineItem(
            message: widget.messages[index],
            index: index,
          );
        },
      ),
    );
  }
}