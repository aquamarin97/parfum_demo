import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:parfume_app/core/constants/app_constants.dart';

import '../../data/models/recommendation.dart';
import 'recommendation_engine.dart';
import 'scoring_rule.dart';

/// Production [RecommendationEngine] driven by `assets/rules/scoring_rules.json`.
///
/// Rule evaluation order:
///   1. **filter** — intersects the candidate set (used for gender partition)
///   2. **exclude** — removes perfumes from candidates (allerji, sevmedikleri)
///   3. **score** — adds +1 to each listed perfume still in candidates
///
/// If all candidates are excluded after step 2, the exclusions are dropped and
/// only the filter partition is used as a safety fallback.
class RuleBasedScoringEngine extends RecommendationEngine {
  static const _rulesAsset = 'assets/rules/scoring_rules.json';

  late final Map<(int, int), List<ScoringRule>> _lookup;
  bool _ready = false;

  @override
  Future<void> initialize() async {
    final raw  = await rootBundle.loadString(_rulesAsset);
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final rules = (data['rules'] as List)
        .map((e) => ScoringRule.fromJson(e as Map<String, dynamic>))
        .toList();

    final lookup = <(int, int), List<ScoringRule>>{};
    for (final rule in rules) {
      lookup.putIfAbsent((rule.questionId, rule.optionIndex), () => []).add(rule);
    }
    _lookup = lookup;
    _ready   = true;
  }

  @override
  Map<int, int> computeScores({
    required String sessionId,
    required Map<int, int> answers,
  }) {
    if (!_ready) return {};

    final filterRules  = <ScoringRule>[];
    final excludeRules = <ScoringRule>[];
    final scoreRules   = <ScoringRule>[];

    for (final MapEntry(:key, :value) in answers.entries) {
      for (final rule in _lookup[(key, value)] ?? const <ScoringRule>[]) {
        switch (rule.type) {
          case ScoringRuleType.filter:  filterRules.add(rule);
          case ScoringRuleType.exclude: excludeRules.add(rule);
          case ScoringRuleType.score:   scoreRules.add(rule);
        }
      }
    }

    final allPerfumes = Set<int>.from(
      Iterable.generate(AppConstants.totalPerfumes, (i) => i + 1),
    );

    // Step 1 — apply filters (gender partition)
    var allowed = allPerfumes;
    for (final rule in filterRules) {
      if (rule.perfumes.isNotEmpty) {
        allowed = allowed.intersection(rule.perfumes.toSet());
      }
    }

    // Step 2 — apply exclusions
    final afterExclude = Set<int>.of(allowed);
    for (final rule in excludeRules) {
      afterExclude.removeAll(rule.perfumes);
    }
    // Safety: never return an empty candidate set
    if (afterExclude.isNotEmpty) allowed = afterExclude;

    // Step 3 — score
    final scores = <int, int>{for (final id in allowed) id: 0};
    for (final rule in scoreRules) {
      for (final id in rule.perfumes) {
        if (scores.containsKey(id)) scores[id] = scores[id]! + rule.pts;
      }
    }

    return scores;
  }

  @override
  Recommendation buildRecommendation(Map<int, int> scores, {int top = 3}) {
    if (scores.isEmpty) return Recommendation(topIds: []);
    final sorted = scores.entries.toList()
      ..sort((a, b) {
        final cmp = b.value.compareTo(a.value);
        return cmp != 0 ? cmp : a.key.compareTo(b.key);
      });
    return Recommendation(
      topIds: sorted.take(top).map((e) => e.key).toList(),
    );
  }
}
