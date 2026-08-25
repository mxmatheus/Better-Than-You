# Phase 0 Report: Canonical Baseline & Pre-Flight Audit

**Status:** APPROVED & COMPLETED  
**Version:** 1.2.1  
**Date:** August 2026  

---

## 1. Phase 0 Objective
To formally specify the canonical Product Constitution, competitive system contracts, mathematical Elo MMR models, deterministic PRNG algorithms, challenge scoring curves, PostgreSQL schema, and state machines for **BETTER THAN YOU** prior to writing production code.

---

## 2. Major Architectural Decisions

1. **Client Score is Never Authoritative:** The Flutter client is an untrusted edge device for rendering, input capture, and optimistic UI. The server independently recalculates scores from raw evidence.
2. **Mulberry32 Determinism:** Standardized on 32-bit Mulberry32 PRNG with bit-identical execution across Dart and TypeScript.
3. **Best-of-7 with Early Termination:** Ranked matches end as soon as a player reaches 4 round wins to maintain peak competitive tension.
4. **Resumable Daily Challenge:** Players can complete their 10 daily rounds anytime before 00:00:00 UTC, with active rounds locking upon app close to prevent cheating.
5. **Aspect-Ratio Independent Precision:** Normalized $1:1$ square play area eliminating phone-vs-tablet advantages.
6. **Relational Submissions Model:** Separated into `matches` $\to$ `match_rounds` $\to$ `round_submissions` with strict PostgreSQL `UNIQUE` constraints and `FOR UPDATE` transaction locks.

---

## 3. Pre-Flight Hostile Audit Findings & Corrections (v1.2.1)

- **Mulberry32 Bitwise Parity:** Fixed Dart VM 64-bit integer bitwise multiplication divergence using explicit 32-bit `_imul` helper. Test vectors independently calculated and verified.
- **Elo Expected-Score Mathematical Precision:**
  Explicitly formulated:
  $$EA = 1 / (1 + 10 ^ ((RB - RA) / 400))$$
  $$EB = 1 / (1 + 10 ^ ((RA - RB) / 400))$$
  Proved $EA + EB = 1.0$ and verified canonical worked examples.
- **Reaction Validation Tiers:** Replaced blanket $<100\text{ms}$ cheating assumptions with a 4-tier model (Scoring, Validation, Flagging, Review).

---

## 4. Phase 0 Exit Criteria Verification

- [x] 3 MVP Challenge specifications defined (Reaction, Memory, Precision).
- [x] Scoring formulas mathematically defined and verified.
- [x] 13-State Match Machine with exhaustive edge cases specified.
- [x] Elo MMR formulation verified with dynamic K-factors ($50, 32, 20$).
- [x] Rank tier thresholds and demotion shields documented.
- [x] Daily Challenge lifecycle, locking, and leaderboard UX specified.
- [x] PostgreSQL schema with idempotency guarantees documented.
- [x] Client/Server responsibility boundaries finalized.

**Final Phase 0 Gate:** `APPROVED — PROCEED TO PHASE 1A`
