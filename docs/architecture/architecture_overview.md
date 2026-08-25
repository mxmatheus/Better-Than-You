# Architecture Overview — BETTER THAN YOU

## 1. System Topology

```text
┌─────────────────────────────────────────────────────────────┐
│                    Flutter Mobile Client                    │
│   (Presentation, Touch Telemetry, Audio, Optimistic UI)     │
└─────────────────────────────────────────────────────────────┘
          │ (WebSocket Subscriptions)     │ (HTTPS REST / RPC)
          ▼                               ▼
┌───────────────────────────────┐ ┌───────────────────────────┐
│       Supabase Realtime       │ │  Supabase Edge Functions  │
│ (State Broadcasts, Opponent   │ │ (Matchmaking, Submission  │
│  Connection Heartbeats)       │ │  Validation, Elo Settlement)
└───────────────────────────────┘ └───────────────────────────┘
          │                                     │
          ▼                                     ▼
┌─────────────────────────────────────────────────────────────┐
│                     PostgreSQL Database                     │
│  - Profiles, Matches, Match Rounds, Round Submissions       │
│  - Daily Challenges, Daily Submissions, Audit Logs          │
│  - Row Level Security (RLS) & Concurrency Row Locks         │
└─────────────────────────────────────────────────────────────┘
```

---

## 2. Core Architectural Axiom

> **CLIENT SCORE IS NEVER AUTHORITATIVE.**
>
> The client is treated as an untrusted edge node. The client renders challenges, collects monotonic touch telemetry, and presents immediate feedback to minimize perceived latency. The backend independently validates raw evidence and computes all official scores.

---

## 3. Client vs Server Responsibility Matrix

| Domain | Client Responsibility | Server Responsibility |
| :--- | :--- | :--- |
| **Seeds & Config** | Interprets server seed into UI layout | Generates, signs, and distributes 32-bit seeds |
| **Challenge Play** | Renders 60/120 FPS UI, captures input timestamps | Enforces strict round timeouts and grace windows |
| **Evidence Submission** | Submits raw touch coordinates and monotonic deltas | Receives and stores immutable raw evidence |
| **Score Computation** | Computes optimistic local score for immediate UI | **Authoritatively recalculates score from raw evidence** |
| **Match Progression** | Animates Split Reveal Card on server broadcast | Manages 13-state match machine and declares round winners |
| **MMR Settlement** | Displays MMR delta animations on summary screen | Executes serializable PostgreSQL transaction with Elo update |
| **Daily Challenge** | Renders 10 rounds and leaderboard slice | Validates single official attempt per UTC day |
| **Anti-Cheat** | Transmits touch contact area and device telemetry | Performs anomaly detection and audits suspicious intervals |

---

## 4. Data Flow for a Ranked Round

```text
1. Server transitions round to ROUND_PREPARING and broadcasts round_seed.
2. Both clients instantiate Mulberry32(round_seed) and prepare canvas.
3. ROUND_ACTIVE begins: Visual challenge is displayed and player interacts.
4. Client records:
   - Monotonic start / render timestamp
   - Monotonic input timestamp
   - Normalized coordinates (x, y)
5. Client sends raw telemetry payload to POST /submit-round.
6. Server validates payload against round_seed and physical thresholds:
   - Recalculates normalized score S in [0, 1000].
   - Commits submission to round_submissions table.
7. Once both submissions arrive (or 2000ms grace expires), server determines round winner.
8. Server broadcasts ROUND_RESULT.
9. Clients trigger animated Split Comparison Reveal Card.
```
