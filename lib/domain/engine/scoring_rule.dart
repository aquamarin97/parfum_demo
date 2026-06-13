/// Rule type applied by [RuleBasedScoringEngine].
enum ScoringRuleType { filter, exclude, score }

/// A single row from `assets/rules/scoring_rules.json`.
///
/// - [filter]  — hard-partition: allowedSet ∩= perfumes (e.g. gender split)
/// - [exclude] — remove from candidates (e.g. allerji, sevmedikleri)
/// - [score]   — add +1 to each listed perfume still in allowedSet
class ScoringRule {
  const ScoringRule({
    required this.questionId,
    required this.optionIndex,
    required this.type,
    required this.perfumes,
    this.pts = 1,
  });

  factory ScoringRule.fromJson(Map<String, dynamic> json) => ScoringRule(
        questionId:  (json['q'] as num).toInt(),
        optionIndex: (json['a'] as num).toInt(),
        type:        ScoringRuleType.values.byName(json['type'] as String),
        perfumes:    (json['perfumes'] as List).cast<int>(),
        pts:         (json['pts'] as num?)?.toInt() ?? 1,
      );

  final int questionId;
  final int optionIndex;
  final ScoringRuleType type;
  final List<int> perfumes;

  /// Points added to each perfume in [perfumes] when this rule fires.
  /// Defaults to 1 if omitted from JSON.
  final int pts;
}
