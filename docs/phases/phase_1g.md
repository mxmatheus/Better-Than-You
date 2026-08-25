# Phase 1G — Adversarial E2E, Concurrency & Anti-Cheat Validation Report

**Status:** COMPLETE  
**Supabase Project:** `better-than-you` (`zlcqkmzwwydjodbzhiyn`)  
**Region:** `eu-central-1` (Frankfurt)  

---

## 1. Attack Matrix & Adversarial Findings

| Attack Vector | Target Surface | Test Payload / Scenario | Result | Action Taken / Hardening |
| :--- | :--- | :--- | :--- | :--- |
| **Direct Profile MMR Mutation** | `public.profiles` | Client executes `UPDATE profiles SET mmr = 9999 WHERE id = auth.uid()` | **BLOCKED** | Implemented `BEFORE UPDATE` trigger `enforce_profile_field_protection()` in `20260826000008` blocking client-side competitive stat mutation. |
| **Direct Daily Submission Insert** | `public.daily_submissions` | Client bypasses RPC with `INSERT INTO daily_submissions (total_score) VALUES (99999)` | **BLOCKED** | Dropped direct client INSERT policy on `daily_submissions`; submissions strictly restricted to `SECURITY DEFINER` RPCs. |
| **Claimed Score Manipulation** | `submit_round_evidence` | Attacker claims `client_claimed_score = 1000` with 550 ms reaction time or 50 ms false start | **NEUTRALIZED** | Claimed score is ignored for authority. Server computes official score (`83` and `0` respectively) from raw monotonic timestamps. |
| **Out-of-Bounds Tap Telemetry** | `PrecisionValidator` / `score_precision` | Attacker submits coordinates $(5.0, -2.0)$ or distance $d > 0.12$ | **REJECTED / FLAGGED** | Validator flags coordinates outside $[0.0, 1.0]$ with `FLAGGED` status and assigns score `0` (`MISS`). |
| **False Start / Early Tap** | `ReactionValidator` / `score_reaction` | Attacker submits reaction $t < 100\text{ ms}$ (e.g. 50 ms, -20 ms) | **PENALIZED** | Categorized as `EARLY_FAULT` with score strictly `0`. |
| **Memory Sequence Forgery** | `MemoryScorer` / `score_memory` | Incomplete or forged sequence claiming full completion | **RECALCULATED** | Accurately scored for valid prefix count ($750 \times \text{correct} / N$) with $0$ speed bonus awarded for incomplete sequences. |
| **Matchmaking Race Condition** | `matchmaking_queue` | Simultaneous pairing requests from multiple concurrent clients | **PREVENTED** | Controlled via `SELECT ... FOR UPDATE SKIP LOCKED`, preventing double-matching. |
| **Settlement Replay / Race** | `settle_match_internal` | Consecutive or parallel calls to settle match | **IDEMPOTENT** | Idempotency guard (`IF status = 'SETTLED' THEN RETURN;`) ensures exactly 1 Elo transaction and no duplicate rating adjustment. |
| **Daily Resumption Replay** | `start_or_resume_daily_challenge` | Re-opening challenge after completion | **IMMUTABLE** | `UNIQUE(challenge_date, user_id)` and completed state lock return existing final score without creating new attempts. |

---

## 2. Live Two-Client Concurrency Evidence

- **Match ID:** `9dad906b-9683-4d10-8e6c-6f912339302c`
- **Player Alpha (Client A):** `a0000000-0000-0000-0000-000000000001` (Starting MMR: `1000`)
- **Player Beta (Client B):** `b0000000-0000-0000-0000-000000000002` (Starting MMR: `1000`)
- **Match Outcome:** Player Alpha won 4-0 (Early termination triggered on 4th win).
- **Final Settled MMR:** Player Alpha: `1025` ($\Delta = +25$), Player Beta: `975` ($\Delta = -25$).
- **Idempotency Check:** Repeated executions of `settle_match_internal` produced $0$ additional MMR change.
- **Daily Challenge Idempotency:** Daily submission for user `a0000000-0000-0000-0000-000000000001` on date `2026-08-26` yielded score `6680` and was marked immutable (`COMPLETED`).

---

## 3. Security Advisor Audit
- Ran `get_advisors(type: "security")`:
  - **Function Search Path:** Hardened with explicit `SET search_path = public`.
  - **Internal Function Privileges:** `EXECUTE` revoked from `anon` and `public`.
  - **Secrets:** 0 service-role keys or passwords committed.

---

## 4. Verification Results
- **Automated Tests:** **76 / 76 PASSED** (100% clean).
- **Static Analysis:** `flutter analyze` completed with **0 issues**.

---

## 5. Remaining Limitations
- Telemetry anomalies (e.g. repeated $100\text{ ms}$ taps) are logged to `audit_logs` for review; automated shadow-banning can be enabled after establishing baseline statistical distributions in production.

---

## 6. Final Phase 1G Verdict

**PHASE 1G — COMPLETE**
