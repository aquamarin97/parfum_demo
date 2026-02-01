// seeded_random_scoring_engine.dart file
import '../../core/constants/app_constants.dart';
import '../../core/utils/seeded_random.dart';
import '../../data/models/recommendation.dart';
import 'recommendation_engine.dart';

class SeededRandomScoringEngine implements RecommendationEngine {
  @override
  Map<int, int> computeScores({
    required String sessionId,
    required Map<int, int> answers,
  }) {
    final scores = <int, int>{};
    for (var id = 1; id <= AppConstants.totalPerfumes; id++) {
      scores[id] = 0;
    }

    for (final entry in answers.entries) {
      final questionId = entry.key;
      final optionIndex = entry.value;
      final seedInput = '$sessionId:$questionId:$optionIndex';
      final seed = SeededRandom.hashSeed(seedInput);
      final random = SeededRandom(seed);
      final picked = _pickPerfumes(random);
      for (final perfumeId in picked) {
        scores[perfumeId] = (scores[perfumeId] ?? 0) + 1;
      }
    }

    return scores;
  }

  @override
  Recommendation buildRecommendation(Map<int, int> scores, {int top = 3}) {
    final entries = scores.entries.toList()
      ..sort((a, b) {
        final scoreCompare = b.value.compareTo(a.value);
        if (scoreCompare != 0) {
          return scoreCompare;
        }
        return a.key.compareTo(b.key);
      });
    final topIds = entries.take(top).map((entry) => entry.key).toList();
    return Recommendation(topIds: topIds);
  }

  List<int> _pickPerfumes(SeededRandom random) {
    final picks = <int>{};
    while (picks.length < AppConstants.scoringPickCount) {
      final id = random.nextInt(AppConstants.totalPerfumes) + 1;
      picks.add(id);
    }
    return picks.toList();
  }
}