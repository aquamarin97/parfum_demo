import 'package:flutter/material.dart';
import 'package:parfume_app/core/constants/app_constants.dart';
import 'package:parfume_app/ui/components/top_nav_bar.dart';
import 'package:parfume_app/ui/theme/app_sizes.dart';

import '../../viewmodel/app_view_model.dart';
import '../components/radio_option_list.dart';
import '../theme/app_text_styles.dart';

/// Displays a single survey question with animated transitions.
class QuestionScreen extends StatefulWidget {
  const QuestionScreen({super.key, required this.viewModel});

  final AppViewModel viewModel;

  @override
  State<QuestionScreen> createState() => _QuestionScreenState();
}

class _QuestionScreenState extends State<QuestionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _questionController;
  late Animation<double> _questionAnimation;
  late Animation<Offset> _questionSlideAnimation;

  /// Tracks the current question text to detect changes in [didUpdateWidget].
  String _currentQuestionText = '';

  @override
  void initState() {
    super.initState();
    _currentQuestionText = widget.viewModel.currentQuestion.text;
    _setupAnimations();
  }

  /// Initialises the question animation controller and starts the entry motion.
  void _setupAnimations() {
    _questionController = AnimationController(
      duration: AppConstants.questionAnimationDuration,
      vsync: this,
    );

    _questionAnimation = CurvedAnimation(
      parent: _questionController,
      curve: Curves.easeOut,
    );

    _questionSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(_questionAnimation);

    _questionController.forward();
  }

  @override
  void didUpdateWidget(QuestionScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newQuestionText = widget.viewModel.currentQuestion.text;
    if (_currentQuestionText != newQuestionText) {
      _currentQuestionText = newQuestionText;
      _questionController
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final question = widget.viewModel.currentQuestion;
    final selection = widget.viewModel.currentSelectionIndex;
    final strings = widget.viewModel.strings;

    return Column(
      children: [
        TopNavBar(
          title: widget.viewModel.progressLabel,
          backLabel: strings.t('back'),
          cancelLabel: strings.t('cancel'),
          onBack: widget.viewModel.goBackQuestion,
          onCancel: widget.viewModel.cancelToIdle,
          backEnabled: widget.viewModel.canGoBack,
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.screenPaddingH,
              vertical: AppSizes.spacingM,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FadeTransition(
                    opacity: _questionAnimation,
                    child: SlideTransition(
                      position: _questionSlideAnimation,
                      child: Text(
                        question.text,
                        key: ValueKey(question.text),
                        style: AppTextStyles.title,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSizes.spacingM),
                  RadioOptionList(
                    key: ValueKey(question.text),
                    options: question.options,
                    selectedIndex: selection,
                    onSelect: widget.viewModel.answerCurrentQuestion,
                    isRtl: widget.viewModel.language.isRtl,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
