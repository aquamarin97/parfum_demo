import 'package:flutter/foundation.dart';

/// The result of the recommendation engine — an ordered list of perfume IDs.
///
/// [topIds] is sorted from most to least recommended. The UI displays
/// up to three entries as tester options.
@immutable
class Recommendation {
  const Recommendation({required this.topIds});

  /// Ordered list of recommended perfume IDs, most relevant first.
  final List<int> topIds;

  /// Returns a mock [Recommendation] for use in debug builds and tests.
  ///
  /// Not intended for production use — guarded by [kDebugMode] at the
  /// call site in [AppViewModel.goToResult].
  factory Recommendation.mock() => const Recommendation(
        topIds: [101, 202, 303],
      );
}