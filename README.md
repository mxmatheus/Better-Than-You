# BETTER THAN YOU

> **Are you actually better? Prove it.**

BETTER THAN YOU is a competitive mobile skill platform built around short, deterministic challenges, real-time 1v1 competition, Elo-based MMR progression, and global daily leaderboards.

---

## Development Status

| Phase | Description | Status |
| :--- | :--- | :--- |
| **Phase 0** | Product Constitution, Elo MMR Math & Pre-Flight System Audit | **COMPLETE** |
| **Phase 1A** | Flutter Scaffolding, Geometric Design System & Core Domain Contracts | **COMPLETE** |
| **Phase 1B** | Challenge Engine, Mulberry32 PRNG & Local Scoring Unit Tests | **NEXT** |
| **Phase 1C** | Split Comparison Card & UX Choreography | PENDING |
| **Phase 1D** | Backend Foundation, PostgreSQL DDL & Edge Functions | PENDING |
| **Phase 1E** | Authoritative Ranked Multiplayer & Real-Time Rooms | PENDING |
| **Phase 1F** | Daily Challenge Lifecycle & Global Leaderboard | PENDING |
| **Phase 1G** | End-to-End Stress Testing & Security Audit | PENDING |

---

## Core Gameplay Loop

```text
PLAY → PERFORM → UNCERTAINTY → REVEAL → COMPARE → WIN/LOSE → RANK CHANGE → PLAY AGAIN
```

1. **Deterministic Challenge:** Both players receive the exact same challenge configuration generated from a 32-bit server seed.
2. **Independent Execution:** Players compete without observing the opponent's active actions.
3. **Split Comparison Reveal:** At round completion, a signature horizontally split comparison card animates into place, comparing player metrics, normalized scores, and declaring the round winner.
4. **Authoritative Outcome:** Match results and Elo MMR updates are calculated and settled authoritatively on the backend.

---

## The 3 MVP Challenges

- **REACTION (Visual Reaction):** React to a visual color trigger as quickly as possible. Evaluated in milliseconds ($t_{\text{rx}}$) with an exponential decay scoring curve ($0 - 1000\text{ pts}$).
- **MEMORY (Spatial Sequence Reproduction):** Memorize and reproduce an illuminated sequence on a $3 \times 3$ grid. Evaluates sequence accuracy ($750\text{ pts}$) with a speed bonus ($250\text{ pts}$) on $100\%$ accuracy.
- **PRECISION (Target Accuracy):** Tap as close as possible to the center of a shrinking target in a $1:1$ square arena. Evaluates normalized distance error ($850\text{ pts}$) and tap timing ($150\text{ pts}$).

---

## Game Modes

### 1. Ranked 1v1
- **Match Length:** Best of 7 rounds (first to 4 wins early termination).
- **Matchmaking:** MMR-based matchmaking with expanding search windows over queue duration.
- **Rating Model:** Modified Elo system with dynamic K-factors ($K=50$ Provisional, $K=32$ Standard, $K=20$ High MMR) and demotion shields.

### 2. Daily Challenge
- **Structure:** 10 universal deterministic rounds.
- **Attempt Rule:** Exactly **ONE OFFICIAL ATTEMPT** per daily UTC cycle.
- **Resumption:** Cycle-resumable anytime before 00:00:00 UTC; active rounds lock on pause to prevent cheating.
- **Leaderboards:** Global rankings sorted by `total_score DESC`, then `submitted_at ASC`.

---

## Competitive Integrity Philosophy

> **"CLIENT SCORE IS NEVER AUTHORITATIVE."**

- The client is an untrusted presentation and input capture layer.
- The server generates all seeds, manages round state machines, independently validates raw telemetry against physical thresholds ($t_{\text{rx}} \ge 100\text{ ms}$), recalculates scores, and executes transactional settlements.

---

## Technology Stack

- **Mobile Client:** Flutter 3.x (Dart 3.x) — High-performance 60/120 FPS rendering, monotonic clock telemetry, geometric design system.
- **Deterministic PRNG:** 32-bit **Mulberry32** with bit-identical execution across Dart and TypeScript.
- **Authoritative Backend:** Supabase + PostgreSQL + Supabase Edge Functions.
- **Real-Time Transport:** Supabase Realtime (WebSockets).

---

## Project Structure

```text
happy-goodall/
├── docs/
│   ├── product/
│   │   ├── product_constitution.md
│   │   └── implementation_plan.md
│   ├── architecture/
│   │   ├── architecture_overview.md
│   │   └── challenge_engine.md
│   └── phases/
│       ├── phase_0.md
│       └── phase_1a.md
├── lib/
│   ├── main.dart
│   ├── core/
│   │   ├── routing/          # AppRouter & AppRoutes
│   │   └── theme/            # AppColors, AppTypography, AppTheme
│   ├── domain/
│   │   ├── challenge/        # ChallengeType, Config, Evidence, Result
│   │   ├── match/            # MatchLifecycleState, RoundOutcome
│   │   └── profile/          # PlayerProfile, RankTier, Skill Identity
│   └── presentation/
│       └── home/             # HomeScreen HUD & Mode Cards
└── test/
    └── widget_test.dart      # Baseline rendering & navigation tests
```

---

## Documentation Links

- [Product Constitution](docs/product/product_constitution.md)
- [Canonical System Specification & Implementation Plan](docs/product/implementation_plan.md)
- [Architecture Overview & Client/Server Boundaries](docs/architecture/architecture_overview.md)
- [Challenge Engine Abstraction Contract](docs/architecture/challenge_engine.md)
- [Phase 0 Exit Report](docs/phases/phase_0.md)
- [Phase 1A Scaffolding Report](docs/phases/phase_1a.md)
