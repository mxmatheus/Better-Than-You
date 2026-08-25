class Mulberry32 {
  int _state;

  Mulberry32(int seed) : _state = seed & 0xFFFFFFFF;

  static int _imul(int a, int b) {
    final aLo = a & 0xFFFF;
    final aHi = (a >> 16) & 0xFFFF;
    final bLo = b & 0xFFFF;
    final bHi = (b >> 16) & 0xFFFF;
    return ((aLo * bLo) + (((aHi * bLo + aLo * bHi) & 0xFFFF) << 16)) &
        0xFFFFFFFF;
  }

  /// Returns unsigned 32-bit integer in [0, 4294967295]
  int nextUint32() {
    _state = (_state + 0x6D2B79F5) & 0xFFFFFFFF;
    var t = _state;
    t = _imul(t ^ (t >> 15), t | 1);
    t = (t ^ (t + _imul(t ^ (t >> 7), t | 61))) & 0xFFFFFFFF;
    return (t ^ (t >> 14)) & 0xFFFFFFFF;
  }

  /// Returns double in [0.0, 1.0)
  double nextFloat() {
    return nextUint32() / 4294967296.0;
  }

  /// Returns integer in range [min, max] inclusive
  int nextInt(int min, int max) {
    assert(min <= max, 'min ($min) must be <= max ($max)');
    return min + (nextUint32() % (max - min + 1));
  }
}
