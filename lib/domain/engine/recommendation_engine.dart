import '../../data/models/recommendation.dart';

/// Contract for the perfume recommendation scoring pipeline.
///
/// Implementations compute a score map from survey answers and build
/// a ranked [Recommendation] from those scores. The two steps are
/// intentionally separate to allow intermediate score inspection and
/// to support future rule-based scoring strategies.
///
/// See also:
/// - [SeededRandomScoringEngine] — placeholder implementation (dev only)
/// - [RuleBasedScoringEngine] — production rule-based implementation
abstract class RecommendationEngine {
  /// Optional async initialisation (e.g. loading rules from assets).
  ///
  /// Called once during app startup before the first [computeScores] call.
  /// Default implementation is a no-op.
  Future<void> initialize() async {}

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
