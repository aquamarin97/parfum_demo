import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_sizes.dart';
import '../../theme/app_text_styles.dart';

/// Displays a list of survey options in a responsive two-column grid.
///
/// Options animate in with staggered fade and slide transitions.
/// Odd-count lists centre the last item at half the row width to match
/// the paired items above it. RTL layouts are supported via [isRtl].
class RadioOptionList extends StatefulWidget {
  const RadioOptionList({
    super.key,
    required this.options,
    required this.selectedIndex,
    required this.onSelect,
    this.isRtl = false,
  });

  final List<String> options;
  final int? selectedIndex;
  final ValueChanged<int> onSelect;

  /// When `true`, slide animations are mirrored for RTL layouts.
  final bool isRtl;

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
      final end = (start + 0.6).clamp(0.0, 1.0);
      final interval = CurvedAnimation(
        parent: _controller,
        curve: Interval(start, end, curve: Curves.easeOut),
      );

      _fadeAnimations.add(
        Tween<double>(begin: 0.0, end: 1.0).animate(interval),
      );

      // Even index → left column, odd → right column.
      // Mirror direction for RTL layouts.
      final isLeftSide = i % 2 == 0;
      final xBegin =
          (isLeftSide
                  ? -AppSizes.radioOptionSlideOffset
                  : AppSizes.radioOptionSlideOffset) *
              (widget.isRtl ? -1.0 : 1.0);

      _slideAnimations.add(
        Tween<Offset>(begin: Offset(xBegin, 0), end: Offset.zero)
            .animate(interval),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Builds a single option tile.
  ///
  /// [width] constrains the tile horizontally; pass `null` for full width.
  Widget _buildOption(int index, {double? width}) {
    final isSelected = widget.selectedIndex == index;
    final isCentered = width != null;

    final slideAnimation = isCentered
        ? Tween<Offset>(
            begin: const Offset(0, AppSizes.radioOptionSlideOffset),
            end: Offset.zero,
          ).animate(_fadeAnimations[index])
        : _slideAnimations[index];

    return FadeTransition(
      opacity: _fadeAnimations[index],
      child: SlideTransition(
        position: slideAnimation,
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.radioOptionPadding),
          child: Material(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.1)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(AppSizes.radiusL),
            child: InkWell(
              onTap: () => widget.onSelect(index),
              borderRadius: BorderRadius.circular(AppSizes.radiusL),
              splashColor: AppColors.primary.withValues(alpha: 0.18),
              highlightColor: AppColors.primary.withValues(alpha: 0.10),
              child: Container(
                width: width,
                constraints: const BoxConstraints(
                  minHeight: AppSizes.radioOptionMinHeight,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.radioOptionPaddingH,
                  vertical: AppSizes.radioOptionPaddingV,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppSizes.radiusL),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                    width: AppSizes.radioOptionBorderWidth,
                  ),
                ),
                child: Row(
                  mainAxisSize: isCentered ? MainAxisSize.min : MainAxisSize.max,
                  children: [
                    _buildRadioIndicator(isSelected),
                    const SizedBox(width: AppSizes.spacingS),
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
      ),
    );
  }

  Widget _buildRadioIndicator(bool isSelected) {
    return Container(
      width: AppSizes.radioButtonSize,
      height: AppSizes.radioButtonSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.border,
          width: AppSizes.radioOptionBorderWidth,
        ),
        color: isSelected ? AppColors.primary : Colors.transparent,
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

  /// Builds a single option centred at half the available width,
  /// matching the visual width of paired items.
  Widget _buildCenteredOption(int index) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth / 2) -
            (AppSizes.radioOptionPadding * 2);
        return Center(child: _buildOption(index, width: width));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final optionCount = widget.options.length;

    return Column(
      children: [
        for (int i = 0; i + 1 < optionCount; i += 2)
          _buildPairRow(i, i + 1),
        if (optionCount.isOdd)
          _buildCenteredOption(optionCount - 1),
      ],
    );
  }
}
