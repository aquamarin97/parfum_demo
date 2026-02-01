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

class _TimelineContainerState extends State<TimelineContainer>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late AnimationController _heightController;
  late Animation<double> _heightAnimation;

  @override
  void initState() {
    super.initState();
    _heightController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _heightAnimation =
        Tween<double>(
          begin: _calculateHeight(0),
          end: _calculateHeight(widget.messages.length),
        ).animate(
          CurvedAnimation(parent: _heightController, curve: Curves.easeOut),
        );

    _heightController.forward();
  }

  @override
  void didUpdateWidget(TimelineContainer oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.messages.length != oldWidget.messages.length) {
      // Yükseklik animasyonu
      _heightAnimation =
          Tween<double>(
            begin: _calculateHeight(oldWidget.messages.length),
            end: _calculateHeight(widget.messages.length),
          ).animate(
            CurvedAnimation(parent: _heightController, curve: Curves.easeOut),
          );

      _heightController.forward(from: 0.0);

      // Scroll animasyonu
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
    _heightController.dispose();
    super.dispose();
  }

  // Mesaj sayısına göre yükseklik hesapla
  double _calculateHeight(int messageCount) {
    if (messageCount == 0) return 0;

    const double itemHeight = 116.0; // ✅ 108 → 116 (2-3 satır için)
    const double padding = 32.0;
    const double minHeight = 120.0;
    const double maxHeight = 800.0;

    final calculatedHeight = (messageCount * itemHeight) + padding;

    return calculatedHeight.clamp(minHeight, maxHeight);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.messages.isEmpty) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _heightAnimation,
      builder: (context, child) {
        return Container(
          height: _heightAnimation.value,
          decoration: BoxDecoration(
            color: AppColors.surface.withOpacity(0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border.withOpacity(0.3)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
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
          ),
        );
      },
    );
  }
}
