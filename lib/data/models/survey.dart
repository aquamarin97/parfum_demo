import 'package:flutter/foundation.dart';

import 'question.dart';

/// The complete set of survey questions loaded from the asset bundle.
///
/// [questions] is ordered — the UI presents them sequentially from
/// index 0 to `questions.length - 1`.
@immutable
class Survey {
  const Survey({required this.questions});

  /// Ordered list of survey questions.
  final List<SurveyQuestion> questions;
}