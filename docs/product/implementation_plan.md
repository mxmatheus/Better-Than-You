# BETTER THAN YOU — Phase 0 System Specification & Architecture Plan v1.2.1

**Document Version:** 1.2.1  
**Status:** APPROVED — CANONICAL REPOSITORY BASELINE  
**Product Type:** Competitive Mobile Skill Game  
**Target Platform:** Android (Flutter Client + Authoritative Backend)  

---

## 0. Absolute Architectural Principle

> **CLIENT SCORE IS NEVER AUTHORITATIVE.**
>
> The Flutter client is responsible for:
> - Deterministic visual rendering & animation
> - Low-latency touch/input telemetry capture
> - Monotonic timestamp recording
> - Local optimistic feedback (zero perceived latency)
> - Audio, haptics, and transition choreography
>
> The Backend is authoritative for:
> - Challenge seed generation & distribution
> - Match & round state machines
> - Raw evidence validation & physics verification
> - Score recalculation from raw evidence
> - Round winner & match winner determination
> - Elo MMR calculation & idempotent transaction settlement
> - Daily challenge lifecycle & global leaderboard ordering
> - Anti-cheat anomaly detection & audit logging

---

## 1. Verified Deterministic PRNG Specification (Mulberry32)

To ensure cross-platform reproducibility between Dart (Flutter client) and TypeScript (authoritative backend), the system standardizes on **Mulberry32**.

### 1.1 Canonical Implementations

#### TypeScript Implementation
```typescript
export class Mulberry32 {
  private state: number;

  constructor(seed: number) {
    this.state = seed >>> 0;
  }

  // Returns unsigned 32-bit integer [0, 4294967295]
  public nextUint32(): number {
    let t = (this.state += 0x6D2B79F5) | 0;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return (t ^ (t >>> 14)) >>> 0;
  }

  // Returns floating-point number in [0.0, 1.0)
  public nextFloat(): number {
    return this.nextUint32() / 4294967296.0;
  }

  // Returns integer in range [min, max] inclusive
  public nextInt(min: number, max: number): number {
    return min + (this.nextUint32() % (max - min + 1));
  }
}
```

#### Dart Implementation
```dart
class Mulberry32 {
  int _state;

  Mulberry32(int seed) : _state = seed & 0xFFFFFFFF;

  static int _imul(int a, int b) {
    int aLo = a & 0xFFFF;
    int aHi = (a >> 16) & 0xFFFF;
    int bLo = b & 0xFFFF;
    int bHi = (b >> 16) & 0xFFFF;
    return ((aLo * bLo) + (((aHi * bLo + aLo * bHi) & 0xFFFF) << 16)) & 0xFFFFFFFF;
  }

  int nextUint32() {
    _state = (_state + 0x6D2B79F5) & 0xFFFFFFFF;
    int t = _state;
    t = _imul(t ^ (t >> 15), t | 1);
    t = (t ^ (t + _imul(t ^ (t >> 7), t | 61))) & 0xFFFFFFFF;
    return (t ^ (t >> 14)) & 0xFFFFFFFF;
  }

  double nextFloat() {
    return nextUint32() / 4294967296.0;
  }

  int nextInt(int min, int max) {
    return min + (nextUint32() % (max - min + 1));
  }
}
```

### 1.2 Canonical Test Vectors (Bit-Identical Across Dart & TypeScript)

| Seed | Iteration | `nextUint32()` | `nextFloat()` |
| :--- | :--- | :--- | :--- |
| **`1337`** | #1 | `792042790` | `0.1844118325971067` |
| **`1337`** | #2 | `815997621` | `0.18998925131745636` |
| **`1337`** | #3 | `3480950701` | `0.8104719922412187` |
| **`1337`** | #4 | `2764880138` | `0.6437488221563399` |
| **`1337`** | #5 | `1850162886` | `0.430774615611881` |
| **`314159265`** | #1 | `1158041355` | `0.26962751406244934` |
| **`314159265`** | #2 | `2101024409` | `0.48918286547996104` |
| **`314159265`** | #3 | `43271312` | `0.010074887424707413` |
| **`314159265`** | #4 | `1001472154` | `0.23317340621724725` |
| **`314159265`** | #5 | `2510391038` | `0.5844959612004459` |

---

## 2. Generic Challenge Engine Contract

To ensure that the 3 MVP challenges (Reaction, Memory, Precision) and future categories can be maintained without altering match networking, MMR settlement, or leaderboards, the system defines an extensible abstraction contract:
- `ChallengeDefinition`: Metadata, timeouts, and challenge family identifier.
- `ChallengeGenerator`: Pure function mapping 32-bit seed to deterministic challenge parameters.
- `ChallengeRuntime`: Flutter UI presentation and low-latency input capture surface.
- `ChallengeEvidence`: Raw telemetry payload transmitted to the server.
- `ChallengeValidator`: Server validator checking physical bounds, seeds, and timing.
- `ChallengeScorer`: Server scoring function calculating normalized score ($0 - 1000$).
- `ChallengeResult`: Encapsulated score, raw metric, and validation status.

---

## 3. The 3 MVP Challenge Specifications

### 3.1 Challenge 1: REACTION
- **Objective:** React to a visual trigger as fast as possible upon appearance.
- **Delay Range:** $1500\text{ ms} - 4500\text{ ms}$ (Deterministic via Mulberry32).
- **Scoring Curve:**
  $$S(t) = \begin{cases}
  0 & \text{if False Start, } t < 100\text{ ms, or } t > 600\text{ ms} \\
  1000 & \text{if } 100\text{ ms} \le t \le 160\text{ ms} \\
  \text{round}\left(1000 \cdot \left(1 - \left(\frac{t - 160}{440}\right)^{1.3}\right)\right) & \text{if } 160\text{ ms} < t \le 600\text{ ms}
  \end{cases}$$

### 3.2 Challenge 2: MEMORY
- **Objective:** Reproduce illuminated sequence of length $L=5$ (Ranked) or $L=6$ (Daily) on a $3 \times 3$ grid.
- **Scoring Curve:** Accuracy is primary ($750\text{ pts}$ base); completion time bonus ($250\text{ pts}$ max) awarded only on $100\%$ accuracy:
  $$S(k, L, t_{\text{comp}}) = \begin{cases}
  0 & \text{if } k = 0 \\
  \text{round}\left(750 \cdot \frac{k}{L}\right) & \text{if } 0 < k < L \\
  750 + \text{round}\left(250 \cdot \max\left(0, 1 - \frac{t_{\text{comp}}}{6000}\right)\right) & \text{if } k = L
  \end{cases}$$

### 3.3 Challenge 3: PRECISION
- **Objective:** Tap as close as possible to the center of a shrinking target ($R_{\text{norm}} = 0.12$) within a $1:1$ square arena.
- **Scoring Curve:** Accuracy contributes $850\text{ pts}$, speed contributes $150\text{ pts}$:
  $$S(d, \Delta t) = \begin{cases}
  0 & \text{if } d > R_{\text{norm}} \text{ (Miss) or } \Delta t > 1200\text{ ms} \\
  \text{round}\left(850 \cdot \left(1 - \frac{d}{R_{\text{norm}}}\right)^{1.5} + 150 \cdot \max\left(0, 1 - \frac{\Delta t}{1200}\right)\right) & \text{if } d \le R_{\text{norm}}
  \end{cases}$$

---

## 4. Elo MMR Mathematical Specification

### 4.1 Authoritative Expected-Score Formulations

$$EA = 1 / (1 + 10 ^ ((RB - RA) / 400))$$

$$EB = 1 / (1 + 10 ^ ((RA - RB) / 400))$$

$$\text{Verification: } EA + EB = 1.0$$

### 4.2 Rating Delta Calculations

$$\Delta RA = \text{round}(KA \cdot (SA - EA))$$

$$\Delta RB = \text{round}(KB \cdot (SB - EB))$$

Where $SA, SB \in \{1.0, 0.5, 0.0\}$ and $K \in \{50 \text{ (Provisional)}, 32 \text{ (Standard)}, 20 \text{ (High MMR)}\}$. Minimum $|\Delta R| \ge 1$ on decisive victories.

### 4.3 Worked Examples ($K = 32$)
1. **$RA = 1000, RB = 1000$:** $EA = 0.50, EB = 0.50$. Win $\implies \mathbf{+16} / \mathbf{-16}$.
2. **$RA = 1200, RB = 1000$:** $EA \approx 0.7597, EB \approx 0.2403$. A Win $\implies \mathbf{+8} / \mathbf{-8}$; B Win $\implies \mathbf{-24} / \mathbf{+24}$.
3. **$RA = 1800, RB = 1000$ ($KA = 20, KB = 32$):** $EA \approx 0.9901, EB \approx 0.0099$. A Win $\implies \mathbf{+1} / \mathbf{-1}$ *(guaranteed minimum delta)*.

---

## 5. Match State Machine & Daily Lifecycle

- **Match State Machine:** 13 explicit states (`MATCHMAKING`, `MATCH_FOUND`, `READY`, `ROUND_PREPARING`, `ROUND_ACTIVE`, `WAITING_FOR_SUBMISSIONS`, `VALIDATING`, `ROUND_RESULT`, `NEXT_ROUND`, `MATCH_COMPLETED`, `SETTLING`, `SETTLED`, `ABANDONED`).
- **Ranked Match Rule:** Best-of-7 with 4-win early termination.
- **Daily Challenge:** 10 universal rounds, UTC 00:00 reset, single official attempt, cycle-resumable before reset.
