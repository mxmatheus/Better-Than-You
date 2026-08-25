# Backend Architecture & Authoritative Boundary — BETTER THAN YOU

## 1. Absolute Authority Principle

> **CLIENT SCORE IS NEVER AUTHORITATIVE.**
>
> The mobile client runs on untrusted hardware. The Flutter application is strictly an input capture and rendering engine. Official match progression, evidence validation, score recalculation, round resolution, Elo settlement, and leaderboard maintenance are exclusively owned by the PostgreSQL database and Supabase Edge Functions.

---

## 2. Server Topology & Data Flow

```text
┌─────────────────────────────────────────────────────────────┐
│                    Flutter Mobile Client                    │
│      (Renders UI, captures touch telemetry, sends evidence) │
└─────────────────────────────────────────────────────────────┘
          │                                     │
          │ 1. Realtime Subscriptions           │ 2. HTTPS RPC
          ▼                                     ▼
┌───────────────────────────────┐ ┌───────────────────────────┐
│       Supabase Realtime       │ │  PostgreSQL RPC Functions │
│  - matches                    │ │  - submit_round_evidence  │
│  - match_rounds               │ │  - resolve_round_internal │
│  - round_submissions          │ │  - settle_match_internal  │
└───────────────────────────────┘ └───────────────────────────┘
                                                │
                                                ▼
                                ┌─────────────────────────────┐
                                │     PostgreSQL Database     │
                                │  - profiles                 │
                                │  - matches                  │
                                │  - match_rounds             │
                                │  - round_submissions        │
                                │  - daily_challenges         │
                                │  - daily_submissions        │
                                │  - audit_logs               │
                                └─────────────────────────────┘
```

---

## 3. Database Schema & Tables

### 3.1 `profiles`
Tracks persistent competitive stats and ratings.
- `id` (UUID, Primary Key, references `auth.users`)
- `username` (UNIQUE, 3-20 chars)
- `display_name` (1-30 chars)
- `mmr` (INT, $\ge 0$, default 1000)
- `provisional_matches_remaining` (INT, default 10)
- `matches_played`, `wins`, `losses`, `draws` (INT, $\ge 0$)
- `rank_tier` (`BRONZE` .. `GRANDMASTER`)

### 3.2 `matches`
Authoritative 1v1 match sessions.
- `id` (UUID, Primary Key)
- `player_a_id`, `player_b_id` (UUID references `profiles`, $A \ne B$)
- `status` (`match_lifecycle_state`)
- `match_seed` (BIGINT)
- `scheduled_challenges` (`challenge_type[]`)
- `total_rounds` (7), `target_wins` (4), `current_round_index` (1..7)
- `player_a_score`, `player_b_score` (INT)
- `winner_id` (UUID references `profiles`)
- `player_a_mmr_start`, `player_b_mmr_start`, `player_a_mmr_delta`, `player_b_mmr_delta`
- `settled_at` (TIMESTAMPTZ)

### 3.3 `match_rounds`
Round records within a match.
- `id` (UUID, Primary Key)
- `match_id` (UUID references `matches`)
- `round_index` (INT $\ge 1$)
- `challenge_type` (`REACTION`, `MEMORY`, `PRECISION`)
- `round_seed` (BIGINT)
- `status` (`ROUND_PREPARING`, `ROUND_ACTIVE`, `ROUND_RESULT`, etc.)
- `winner_id` (UUID), `is_draw` (BOOLEAN)
- `UNIQUE(match_id, round_index)`

### 3.4 `round_submissions`
Immutable telemetry submissions with server-recalculated scores.
- `id` (UUID, Primary Key)
- `round_id` (UUID references `match_rounds`)
- `match_id` (UUID references `matches`)
- `player_id` (UUID references `profiles`)
- `client_claimed_score` (INT, recorded for audit only)
- `normalized_score` (INT, 0..1000, **authoritatively computed by server**)
- `raw_metric` (NUMERIC), `formatted_metric` (TEXT)
- `validation_status` (`VALID`, `EARLY_FAULT`, `TIMEOUT`, `FLAGGED`, `REJECTED`)
- `raw_evidence` (JSONB)
- `UNIQUE(round_id, player_id)`

### 3.5 `matchmaking_queue`
Active queue for players awaiting ranked match assignment.
- `id` (UUID, Primary Key)
- `player_id` (UUID UNIQUE references `profiles`)
- `mmr` (INT)
- `enqueued_at` (TIMESTAMPTZ)

---

## 4. Matchmaking & Forfeit RPCs

### 4.1 `find_or_create_match()`
Atomic matchmaking and match generation:
- Checks if player is already in an active match $\to$ returns active match immediately.
- Looks up waiting opponent with `SELECT ... FOR UPDATE SKIP LOCKED` to prevent concurrent pairing race conditions.
- Pairs players, inserts `matches` row with server-generated seed, generates 7 deterministic `match_rounds` rows, and returns match assignment.
- If no opponent is waiting, queues caller into `matchmaking_queue`.

### 4.2 `forfeit_match(p_match_id UUID)`
- Authoritatively awards win to remaining connected player upon disconnect/forfeit.
- Invokes `settle_match_internal` transaction-safely.

---

## 5. Row Level Security (RLS) Model

1. **`profiles`:**
   - SELECT: Public.
   - UPDATE: Authenticated owner (`auth.uid() = id`), restricted to non-competitive fields (`username`, `display_name`, `avatar_url`).
2. **`matches` & `match_rounds`:**
   - SELECT: Only participants (`auth.uid() = player_a_id OR auth.uid() = player_b_id`).
   - Direct INSERT / UPDATE / DELETE: Prohibited for clients. Must go through `SECURITY DEFINER` RPCs.
3. **`round_submissions`:**
   - SELECT: Match participants only.
   - Direct INSERT / UPDATE: Prohibited for clients. Client sends raw evidence to `submit_round_evidence` RPC.
4. **`daily_submissions`:**
   - SELECT: Public.
   - INSERT: Authenticated user for own user_id (`auth.uid() = user_id`).
5. **`audit_logs`:**
   - Service-role only.

---

## 5. Authoritative Challenge Scoring Parity

| Challenge | Generation from `round_seed` | Validation Bounds | Scoring Formula ($S \in [0, 1000]$) |
| :--- | :--- | :--- | :--- |
| **REACTION** | `waitDelayMs = 1500 + PRNG % 3001` | $t < 100\text{ms} \implies \text{FAULT}$<br>$t > 1000\text{ms} \implies \text{TIMEOUT}$ | $100..160\text{ms} \to 1000$<br>$160..600\text{ms} \to \text{round}(1000 \cdot (1 - ((t-160)/440)^{1.3}))$<br>$>600\text{ms} \to 0$ |
| **MEMORY** | Non-repeating tiles on $3 \times 3$ grid | Valid tile indices $0..8$, $k \le L$ | $k < L \to \text{round}(750 \cdot k / L)$<br>$k = L \to 750 + \text{round}(250 \cdot \max(0, 1 - t_{\text{comp}}/6000))$ |
| **PRECISION** | $(x, y) \in [0.18, 0.82]^2$, $R_{\text{norm}} = 0.12$ | Coordinates $\in [0.0, 1.0]^2$, $t \le 1200\text{ms}$ | $d > 0.12 \to 0\text{ (MISS)}$<br>$d \le 0.12 \to \text{round}(850 \cdot (1 - d/0.12)^{1.5} + 150 \cdot \max(0, 1 - t/1200))$ |

---

## 6. Concurrency & Idempotency Strategy

- **Row Locks:** Operations on rounds and matches utilize `SELECT ... FOR UPDATE` to prevent race conditions during simultaneous player submissions.
- **Idempotent Settlement:** `settle_match_internal()` validates that `status <> 'SETTLED'`. Calling settlement multiple times safely exits without duplicate MMR modification.
- **Unique Submission Guard:** `UNIQUE(round_id, player_id)` database constraint guarantees a player cannot submit duplicate evidence for the same round.

---

## 7. Client Monotonic Timestamp Limitation

### Known Boundary Condition
The backend cannot directly inspect hardware clock registers on remote Android devices. Physical touch timing is reconstructed from client monotonic deltas:
- $\Delta t_{\text{reaction}} = t_{\text{touchDown}} - t_{\text{triggerRendered}}$
- $\Delta t_{\text{precision}} = t_{\text{touchDown}} - t_{\text{targetRendered}}$
- $\Delta t_{\text{memory}} = t_{\text{completion}} - t_{\text{inputWindowStart}}$

### Server Mitigations:
1. **Server Round Expiration:** Each round has an authoritative `expires_at` timestamp on the server. Submissions arriving after the deadline are marked `REJECTED_LATE`.
2. **Structural Validation:** Telemetry coordinates and monotonic deltas are checked against physical constraints ($t < 100\text{ms} \to \text{FAULT}$, coordinate out of range $\to \text{FLAGGED}$).
3. **Telemetry Audit:** Full raw interaction JSON is archived in `round_submissions.raw_evidence` for historical audit.
