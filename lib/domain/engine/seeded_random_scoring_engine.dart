import '../../core/constants/app_constants.dart';
import '../../core/utils/seeded_random.dart';
import '../../data/models/recommendation.dart';
import 'recommendation_engine.dart';

/// Placeholder [RecommendationEngine] that produces deterministic but
/// arbitrary recommendations from the session ID and survey answers.
///
/// Each answer is hashed with the session ID to produce a seed, which
/// drives a [SeededRandom] to pick [AppConstants.scoringPickCount] perfume
/// IDs. Perfumes that appear across more answers accumulate higher scores.
///
/// This implementation exists to unblock UI and PLC development while the
/// real rule-based scoring algorithm is designed. Replace with
/// [RuleBasedScoringEngine] before production release.
///
/// See also:
/// - [RuleBasedScoringEngine] — the planned production implementation.
/// - [SeededRandom] — the deterministic PRNG used for picking.
class SeededRandomScoringEngine extends RecommendationEngine {
  /// Computes a score for every perfume in the catalogue.
  ///
  /// Each answer contributes [AppConstants.scoringPickCount] votes,
  /// distributed pseudo-randomly but deterministically from [sessionId]
  /// and the question/answer pair.
  @override
  Map<int, int> computeScores({
    required String sessionId,
    required Map<int, int> answers,
  }) {
    final scores = <int, int>{
      for (var id = 1; id <= AppConstants.totalPerfumes; id++) id: 0,
    };

    for (final entry in answers.entries) {
      final seedInput = '$sessionId:${entry.key}:${entry.value}';
      final random = SeededRandom(SeededRandom.hashSeed(seedInput));
      for (final perfumeId in _pickPerfumes(random)) {
        scores[perfumeId] = (scores[perfumeId] ?? 0) + 1;
      }
    }

    return scores;
  }

  /// Builds a [Recommendation] from [scores], returning the [top] highest
  /// scoring perfume IDs.
  ///
  /// Ties are broken by ascending perfume ID for deterministic ordering.
  @override
  Recommendation buildRecommendation(Map<int, int> scores, {int top = 3}) {
    final sorted = scores.entries.toList()
      ..sort((a, b) {
        final cmp = b.value.compareTo(a.value);
        return cmp != 0 ? cmp : a.key.compareTo(b.key);
      });
    return Recommendation(
      topIds: sorted.take(top).map((e) => e.key).toList(),
    );
  }

  /// Picks [AppConstants.scoringPickCount] unique perfume IDs using [random].
  List<int> _pickPerfumes(SeededRandom random) {
    final picks = <int>{};
    while (picks.length < AppConstants.scoringPickCount) {
      picks.add(random.nextInt(AppConstants.totalPerfumes) + 1);
    }
    return picks.toList();
  }
}