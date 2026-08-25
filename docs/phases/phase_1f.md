# Phase 1F — Daily Challenge Mode & Global Leaderboard Report

**Status:** COMPLETE  
**Supabase Project:** `better-than-you` (`zlcqkmzwwydjodbzhiyn`)  
**Region:** `eu-central-1` (Frankfurt)  

---

## 1. Overview

Phase 1F implements the official **Daily Challenge Mode** and **Global Leaderboard**.

- **Daily Cycle:** 1 official 10-round challenge per UTC calendar day (resets at `00:00 UTC`).
- **One Official Attempt:** Players receive exactly one attempt per calendar day, enforced by database constraint `UNIQUE(challenge_date, user_id)`.
- **Resumption Support:** Interrupted in-progress sessions can be resumed from the exact current round without regenerating challenge seeds or discarding accumulated score.
- **Server Authority:** Client-claimed scores are ignored. Every round's raw evidence is independently validated and scored by PostgreSQL RPCs.
- **Global Leaderboard:** Database-driven rank and percentile calculation with deterministic tie-breaking and a $\pm 3$ nearby player view.

---

## 2. Database Schema & RPCs

### 2.1 Schema Extensions (`20260826000007_daily_challenge_and_leaderboard.sql`)
- **`daily_challenges`:** Stores daily seed and scheduled 10-round challenge sequence.
- **`daily_submissions`:** Tracks `status` (`'IN_PROGRESS'`, `'COMPLETED'`), `current_round_index`, `total_score`, `round_scores`, `raw_evidence`, and `completed_at`.

### 2.2 PostgreSQL RPC Endpoints
1. **`derive_daily_seed(p_date DATE)`:**
   $$\text{Seed} = (((\text{YYYYMMDD}) \times 1664525) + 1013904223) \pmod{2^{32}}$$
   Guarantees identical 32-bit positive integer seed across Dart, TypeScript, and PostgreSQL.
2. **`get_or_create_daily_challenge(p_date DATE)`:** Idempotently initializes the 10 scheduled challenges for any UTC date using Mulberry32.
3. **`start_or_resume_daily_challenge(p_date DATE)`:**
   - Obtains row-level lock on `daily_submissions`.
   - Inserts new attempt if first launch; otherwise returns active or completed state.
4. **`submit_daily_round_evidence(p_date, p_round_index, p_evidence)`:**
   - Validates round sequence and recalculates score authoritatively from raw timestamps and coordinates.
   - Marks status `'COMPLETED'` and records `completed_at` on round 10.
5. **`get_daily_leaderboard(p_date, p_limit)`:**
   - Returns top entries ordered by:
     $$\text{ORDER BY total\_score DESC, completed\_at ASC, user\_id ASC}$$
6. **`get_daily_user_rank(p_date)`:**
   - Computes exact rank, total participants, top percentile, $\pm 3$ nearby player entries, and millisecond countdown to next UTC midnight.

---

## 3. Concurrency & Integrity Strategy

- **One-Attempt Guarantee:** Enforced at the database layer via `UNIQUE(challenge_date, user_id)` and `SELECT ... FOR UPDATE` row locks.
- **Score Immutability:** Completed submissions reject subsequent evidence submissions.
- **Client Untrusted Boundary:** Final total score is the sum of server-calculated round scores. Direct modification of `total_score` or `completed_at` via client REST/GraphQL is blocked by RLS.

---

## 4. Verification & Testing

### 4.1 Automated Test Suite
- **Unit Tests:** 9 test suites covering Mulberry32 vectors, Elo math, challenge scoring curves, daily seed determinism, one-attempt resumption, and leaderboard tie-breaking.
- **Widget Tests:** 7 test suites covering Match HUD, Split Comparison Card choreography, Reaction/Memory/Precision challenge widgets, and Daily Challenge/Leaderboard screens.
- **Results:** **67 / 67 PASSED** (100% clean).
- **Static Analysis:** `flutter analyze` completed with **0 issues**.

---

## 5. Known Limitations
- Real-time leaderboard updates during active play rely on on-demand RPC queries; WebSocket push notifications for rank changes can be added in Phase 2 optimization.
