/// A deterministic pseudo-random number generator seeded with an integer.
///
/// Uses a linear congruential generator (LCG) so the same [seed] always
/// produces the same sequence. This is intentional — it allows the scoring
/// engine to produce reproducible recommendations for a given session ID.
///
/// Not suitable for cryptographic use.
class SeededRandom {
  /// Creates a [SeededRandom] with the given [seed].
  SeededRandom(int seed) : _state = seed & 0x7fffffff;

  int _state;

  /// Returns the next non-negative integer in the range `[0, max)`.
  ///
  /// Throws [ArgumentError] if [max] is not positive.
  int nextInt(int max) {
    if (max <= 0) throw ArgumentError.value(max, 'max', 'must be positive');
    _state = (1103515245 * _state + 12345) & 0x7fffffff;
    return _state % max;
  }

  /// Derives a deterministic integer seed from [input] using a djb2-style
  /// hash, masked to 31 bits.
  ///
  /// Used to convert a session ID string into a numeric seed.
  static int hashSeed(String input) {
    var hash = 0;
    for (final code in input.codeUnits) {
      hash = ((hash << 5) - hash) + code;
      hash &= 0x7fffffff;
    }
    return hash;
  }
}