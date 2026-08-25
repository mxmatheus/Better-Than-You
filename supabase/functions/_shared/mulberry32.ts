/**
 * Canonical Mulberry32 32-bit PRNG implementation.
 * Guarantees bit-identical output to Flutter Dart client for any 32-bit seed.
 */
export class Mulberry32 {
  private state: number;

  constructor(seed: number) {
    this.state = (seed >>> 0);
  }

  /**
   * Returns unsigned 32-bit integer in range [0, 4294967295]
   */
  public nextUint32(): number {
    let t = (this.state += 0x6D2B79F5) | 0;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return (t ^ (t >>> 14)) >>> 0;
  }

  /**
   * Returns floating-point number strictly within [0.0, 1.0)
   */
  public nextFloat(): number {
    return this.nextUint32() / 4294967296.0;
  }

  /**
   * Returns integer within inclusive [min, max] range
   */
  public nextInt(min: number, max: number): number {
    return min + (this.nextUint32() % (max - min + 1));
  }
}
