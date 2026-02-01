// recommendation_engine.dart file
import '../../data/models/recommendation.dart';

abstract class RecommendationEngine {
  Map<int, int> computeScores({
    required String sessionId,
    required Map<int, int> answers,
  });

  Recommendation buildRecommendation(Map<int, int> scores, {int top = 3});
}