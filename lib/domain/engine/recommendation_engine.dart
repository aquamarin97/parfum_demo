import '../../data/models/recommendation.dart';

/// Contract for the perfume recommendation scoring pipeline.
///
/// Implementations compute a score map from survey answers and build
/// a ranked [Recommendation] from those scores. The two steps are
/// intentionally separate to allow intermediate score inspection and
/// to support future rule-based scoring strategies.
///
/// See also:
/// - [SeededRandomScoringEngine] — current placeholder implementation
/// - [RuleBasedScoringEngine] — planned rule-based implementation
abstract interface class RecommendationEngine {
  /// Computes a score map from survey [answers].
  ///
  /// [sessionId] may be used for seeding or logging.
  /// [answers] maps question ID → selected option index.
  /// Returns a map of perfume ID → computed score.
  Map<int, int> computeScores({
    required String sessionId,
    required Map<int, int> answers,
  });

  /// Builds a [Recommendation] from a pre-computed [scores] map.
  ///
  /// [top] controls the maximum number of recommendations returned.
  Recommendation buildRecommendation(Map<int, int> scores, {int top = 3});
}