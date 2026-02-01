// seeded_random.dart file
class SeededRandom {
  SeededRandom(int seed) : _state = seed & 0x7fffffff;

  int _state;

  int nextInt(int max) {
    if (max <= 0) {
      throw ArgumentError('max must be positive');
    }
    _state = (1103515245 * _state + 12345) & 0x7fffffff;
    return _state % max;
  }

  static int hashSeed(String input) {
    var hash = 0;
    for (final code in input.codeUnits) {
      hash = ((hash << 5) - hash) + code;
      hash &= 0x7fffffff;
    }
    return hash;
  }
}