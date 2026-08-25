import 'package:flutter_test/flutter_test.dart';
import 'package:better_than_you/core/utils/mulberry32.dart';

void main() {
  group('Mulberry32 PRNG Canonical Test Vectors', () {
    test('Seed 1337 matches verified 5-iteration uint32 and float vectors', () {
      final prng = Mulberry32(1337);

      final expectedUints = [
        792042790,
        815997621,
        3480950701,
        2764880138,
        1850162886,
      ];

      final expectedFloats = [
        0.1844118325971067,
        0.18998925131745636,
        0.8104719922412187,
        0.6437488221563399,
        0.430774615611881,
      ];

      for (var i = 0; i < 5; i++) {
        final u = prng.nextUint32();
        expect(u, equals(expectedUints[i]),
            reason: 'Iteration ${i + 1} uint32 mismatch');
        final f = u / 4294967296.0;
        expect(f, closeTo(expectedFloats[i], 1e-12),
            reason: 'Iteration ${i + 1} float mismatch');
      }
    });

    test('Seed 314159265 matches verified 5-iteration uint32 and float vectors', () {
      final prng = Mulberry32(314159265);

      final expectedUints = [
        1158041355,
        2101024409,
        43271312,
        1001472154,
        2510391038,
      ];

      final expectedFloats = [
        0.26962751406244934,
        0.48918286547996104,
        0.010074887424707413,
        0.23317340621724725,
        0.5844959612004459,
      ];

      for (var i = 0; i < 5; i++) {
        final u = prng.nextUint32();
        expect(u, equals(expectedUints[i]),
            reason: 'Iteration ${i + 1} uint32 mismatch');
        final f = u / 4294967296.0;
        expect(f, closeTo(expectedFloats[i], 1e-12),
            reason: 'Iteration ${i + 1} float mismatch');
      }
    });

    test('PRNG is 100% reproducible with identical seed', () {
      final prngA = Mulberry32(987654321);
      final prngB = Mulberry32(987654321);

      for (var i = 0; i < 50; i++) {
        expect(prngA.nextUint32(), equals(prngB.nextUint32()));
      }
    });

    test('Different seeds produce different sequences', () {
      final prngA = Mulberry32(1111);
      final prngB = Mulberry32(2222);

      final seqA = List.generate(10, (_) => prngA.nextUint32());
      final seqB = List.generate(10, (_) => prngB.nextUint32());

      expect(seqA, isNot(equals(seqB)));
    });

    test('nextFloat produces values strictly within [0.0, 1.0)', () {
      final prng = Mulberry32(42);

      for (var i = 0; i < 1000; i++) {
        final val = prng.nextFloat();
        expect(val, greaterThanOrEqualTo(0.0));
        expect(val, lessThan(1.0));
      }
    });

    test('nextInt generates integers within inclusive [min, max] bounds', () {
      final prng = Mulberry32(12345);

      const min = 1500;
      const max = 4500;

      for (var i = 0; i < 1000; i++) {
        final val = prng.nextInt(min, max);
        expect(val, greaterThanOrEqualTo(min));
        expect(val, lessThanOrEqualTo(max));
      }
    });
  });
}
