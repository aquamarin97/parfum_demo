// radio_option_list.dart (güncellenmiş - tek şıklar için genişlik düzeltmesi)
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class RadioOptionList extends StatefulWidget {
  const RadioOptionList({
    super.key,
    required this.options,
    required this.selectedIndex,
    required this.onSelect,
  });

  final List<String> options;
  final int? selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  State<RadioOptionList> createState() => _RadioOptionListState();
}

class _RadioOptionListState extends State<RadioOptionList>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _fadeAnimations;
  late List<Animation<Offset>> _slideAnimations;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _initializeAnimations();
    _controller.forward();
  }

  void _initializeAnimations() {
    _fadeAnimations = [];
    _slideAnimations = [];

    for (int i = 0; i < widget.options.length; i++) {
      final start = i * 0.1;
      final end = start + 0.6;

      _fadeAnimations.add(
        Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _controller,
            curve: Interval(start, end.clamp(0.0, 1.0), curve: Curves.easeOut),
          ),
        ),
      );

      final isLeftSide = i % 2 == 0;
      _slideAnimations.add(
        Tween<Offset>(
          begin: Offset(isLeftSide ? -0.3 : 0.3, 0),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _controller,
            curve: Interval(start, end.clamp(0.0, 1.0), curve: Curves.easeOut),
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildOption(int index, {bool isCentered = false}) {
    final isSelected = widget.selectedIndex == index;

    return FadeTransition(
      opacity: _fadeAnimations[index],
      child: SlideTransition(
        position: isCentered
            ? Tween<Offset>(
                begin: const Offset(0, 0.3),
                end: Offset.zero,
              ).animate(_fadeAnimations[index])
            : _slideAnimations[index],
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: InkWell(
            onTap: () => widget.onSelect(index),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              constraints: const BoxConstraints(
                minHeight: 80,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withOpacity(0.1)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.border,
                  width: 2,
                ),
              ),
              child: Row(
                mainAxisSize: isCentered ? MainAxisSize.min : MainAxisSize.max,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color:
                            isSelected ? AppColors.primary : AppColors.border,
                        width: 2,
                      ),
                      color:
                          isSelected ? AppColors.primary : Colors.transparent,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Flexible(
                    child: Text(
                      widget.options[index],
                      style: AppTextStyles.body,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPairRow(int index1, int index2) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _buildOption(index1)),
          Expanded(child: _buildOption(index2)),
        ],
      ),
    );
  }

  // Tek şık için LayoutBuilder ile ekranın yarısı kadar genişlik
  Widget _buildCenteredOption(int index) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Çiftli şıklarla aynı genişlikte olması için
        // Padding dahil ekranın yarısını kullan (8*2 = 16 padding var)
        final width = (constraints.maxWidth / 2) - 16;
        
        return Center(
          child: FadeTransition(
            opacity: _fadeAnimations[index],
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.3),
                end: Offset.zero,
              ).animate(_fadeAnimations[index]),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: InkWell(
                  onTap: () => widget.onSelect(index),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: width,
                    constraints: const BoxConstraints(
                      minHeight: 80,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                    decoration: BoxDecoration(
                      color: widget.selectedIndex == index
                          ? AppColors.primary.withOpacity(0.1)
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: widget.selectedIndex == index
                            ? AppColors.primary
                            : AppColors.border,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: widget.selectedIndex == index
                                  ? AppColors.primary
                                  : AppColors.border,
                              width: 2,
                            ),
                            color: widget.selectedIndex == index
                                ? AppColors.primary
                                : Colors.transparent,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            widget.options[index],
                            style: AppTextStyles.body,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final optionCount = widget.options.length;

    // 2 şık: Bir row içinde
    if (optionCount == 2) {
      return _buildPairRow(0, 1);
    }

    // 3 şık: İlk iki row'da, üçüncü centered
    if (optionCount == 3) {
      return Column(
        children: [
          _buildPairRow(0, 1),
          _buildCenteredOption(2),
        ],
      );
    }

    // 4 şık: 2x2 grid
    if (optionCount == 4) {
      return Column(
        children: [
          _buildPairRow(0, 1),
          _buildPairRow(2, 3),
        ],
      );
    }

    // 5 şık: 2x2 + 1 centered
    if (optionCount == 5) {
      return Column(
        children: [
          _buildPairRow(0, 1),
          _buildPairRow(2, 3),
          _buildCenteredOption(4),
        ],
      );
    }

    // 6 şık: 3x2 grid
    if (optionCount == 6) {
      return Column(
        children: [
          _buildPairRow(0, 1),
          _buildPairRow(2, 3),
          _buildPairRow(4, 5),
        ],
      );
    }

    // 7 şık: 3x2 + 1 centered
    if (optionCount == 7) {
      return Column(
        children: [
          _buildPairRow(0, 1),
          _buildPairRow(2, 3),
          _buildPairRow(4, 5),
          _buildCenteredOption(6),
        ],
      );
    }

    // Fallback: Dikey liste
    return Column(
      children: List.generate(
        optionCount,
        (index) => _buildOption(index),
      ),
    );
  }
}