// rule_based_scoring_engine_TODO.dart file
import '../../data/models/recommendation.dart';
import 'recommendation_engine.dart';

class RuleBasedScoringEngineTodo implements RecommendationEngine {
  @override
  Map<int, int> computeScores({
    required String sessionId,
    required Map<int, int> answers,
  }) {
    // TODO: Replace with real rule-based scoring logic.
    return {};
  }

  @override
  Recommendation buildRecommendation(Map<int, int> scores, {int top = 3}) {
    // TODO: Implement once rule-based scoring is added.
    return Recommendation(topIds: []);
  }
}