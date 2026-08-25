# Better Than You

**Better Than You** is a competitive 1v1 mobile skill game built with Flutter and Supabase. Players face off in fast, deterministic micro-challenges where every millisecond, pixel, and sequence step counts.

Matches are blind during play: you compete under identical deterministic seed conditions without seeing the opponent's actions in real time. Once both players submit their round telemetry, an animated Split Reveal Card displays the head-to-head comparison, awards the round point, and updates the match score.

---

## Gameplay

Ranked matches follow a **Best-of-7** format with early termination as soon as a player secures **4 wins**.

### Challenge Types

- **Reaction:** Visual reflex challenge. Players react to an on-screen state change. Submissions below 100 ms are locked out as false starts (`EARLY_FAULT`), while scores decay exponentially between 160 ms and 600 ms.
- **Memory:** Sequence recall on a 3x3 geometric grid. Partial sequences receive accuracy points; full sequences earn additional speed bonuses based on completion time.
- **Precision:** Shrinking target accuracy in a 1:1 arena. Scores blend Euclidean distance from center (850 points max) with tap speed (150 points max).

---

## Architecture

The system operates on an untrusted-client model. The mobile client renders challenges, collects monotonic touch telemetry, and provides optimistic local feedback, but **client scores are never authoritative**.

```text
Flutter Mobile Client
  │ (Raw Telemetry: timestamps, touch coordinates)
  ▼
MatchRepository (Local / Supabase)
  │ (HTTPS RPC / WebSockets)
  ▼
Supabase Edge Functions / PostgreSQL RPCs
  ├── Server-side Mulberry32 PRNG
  ├── Authoritative Score Recalculation
  ├── Concurrency Locks (SELECT ... FOR UPDATE)
  └── Transaction-Safe Elo MMR Settlement
  │
  ▼
PostgreSQL Database + Row Level Security
```

- **Seeds & Rounds:** Generated server-side using Mulberry32 for bit-identical reproducibility across Dart and PostgreSQL/TypeScript.
- **Evidence Validation:** The server recalculates normalized scores ($0 - 1000$) directly from raw coordinates and timestamps.
- **MMR Settlement:** An Elo rating system with dynamic K-factors ($K=50$ for provisional players, $K=32$ standard, $K=20$ for high MMR) calculates rating adjustments upon match completion with guaranteed minimum deltas on decisive wins.
- **Idempotency:** Unique submission constraints and row-level locks prevent duplicate submissions, race conditions, or duplicate rating adjustments.

---

## Tech Stack

- **Client:** Flutter / Dart (Material 3 Dark Theme)
- **Backend:** Supabase (Auth, Edge Functions, Realtime)
- **Database:** PostgreSQL (PL/pgSQL functions, Row Level Security)
- **RNG:** 32-bit Mulberry32 PRNG

---

## Project Structure

```text
lib/
  core/           # Theme, routing, haptics, audio, Supabase config, utilities
  domain/         # Challenge definitions, generators, scorers, match models
  presentation/   # Flutter screens, challenge widgets, HUD, Split Comparison Card
supabase/
  migrations/     # PostgreSQL schema, RLS policies, PRNG, and RPC functions
  functions/      # TypeScript edge functions and shared domain contracts
test/
  unit/           # PRNG vectors, scoring curves, Elo math, backend authority tests
  widget/         # Challenge widgets, animation choreography, match flow tests
docs/
  architecture/   # System topology, backend specifications, challenge engine contracts
  phases/         # Implementation milestone records
```

---

## Development Status

- **Phase 0:** System Architecture & Elo Mathematical Specification — `COMPLETE`
- **Phase 1A:** Flutter Scaffolding & Dark Geometric UI Foundation — `COMPLETE`
- **Phase 1B:** Deterministic Challenge Engine (Reaction, Memory, Precision) — `COMPLETE`
- **Phase 1C:** Interactive Local Gameplay Loop & Split Reveal Card — `COMPLETE`
- **Phase 1D:** Supabase Backend Foundation & Database Migrations — `COMPLETE`
- **Phase 1E:** Authoritative Ranked Multiplayer & Live Elo Settlement — `COMPLETE`
- **Phase 1F:** Daily Challenge Mode & Global Leaderboard — `NEXT`

---

## Local Development

### Prerequisites

- Flutter SDK `^3.11.5`
- Node.js / `npx` (for Supabase CLI)

### Flutter Setup

Install dependencies:
```bash
flutter pub get
```

Run static analysis:
```bash
flutter analyze
```

Run unit and widget tests:
```bash
flutter test
```

Launch the mobile app:
```bash
flutter run
```

### Local Supabase Development

Start local Supabase containers:
```bash
npx supabase start
```

Apply migrations locally:
```bash
npx supabase db reset
```

Serve Edge Functions:
```bash
npx supabase functions serve
```
