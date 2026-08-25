# BETTER THAN YOU

## Product Constitution & System Contract

**Document Version:** 1.0.0  
**Status:** CANONICAL BASELINE  
**Product Type:** Competitive Mobile Skill Game  
**Platform:** Android  
**Primary Mode:** Online 1v1 Ranked  
**Secondary Mode:** Daily Challenge  
**Core Promise:** **Prove you're better.**

---

# 1. PRODUCT IDENTITY

## 1.1 Executive Summary
BETTER THAN YOU is a competitive mobile skill game where two players are matched against each other and compete across a sequence of short, deterministic skill challenges.

Each player receives the exact same challenge conditions.

Players do not observe each other's actions during a round.

After each round, the game reveals a split comparison showing each player's performance.

A complete match consists of multiple rounds.

The player who performs better across the match wins.

Ranked matches affect MMR.

The Daily Challenge is a separate universal challenge where every player receives the same sequence and competes for leaderboard position.

The product is built around one psychological proposition:

> **Everyone thinks they're better. Prove it.**

---

# 2. PRODUCT PHILOSOPHY

## 2.1 Core Principle
The game must never primarily feel like a collection of mini-games.

It must feel like:

> **A competitive test of human skill.**

Individual challenges are interchangeable components.

The competitive comparison is the product.

## 2.2 Core Emotional Loop
The intended emotional sequence is:

$$\text{Challenge} \to \text{Attempt} \to \text{Uncertainty} \to \text{Result Reveal} \to \text{Comparison} \to \text{Victory / Defeat} \to \text{Progression} \to \text{Rematch}$$

The player should repeatedly experience:
> “I can do better.”

and eventually:
> “I need to beat that player.”

---

# 3. DESIGN PILLARS

## Pillar 1 — Skill
Results must primarily reflect player skill. Randomness may exist to create variety, but it must never determine the winner.

## Pillar 2 — Fairness
Both players must receive equivalent challenge conditions. No player should receive an easier or harder version of a competitive round because of matchmaking, rank, purchase status, or other external factors.

## Pillar 3 — Speed
Individual rounds should generally be short ($3–8\text{ seconds}$). The player should understand the task almost immediately.

## Pillar 4 — Comparison
The player must clearly understand: *How did I perform compared to my opponent?*

## Pillar 5 — Replayability
The same challenge category must support many variations without requiring manual content production for every round. Procedural generation and deterministic seeds are mandatory.

## Pillar 6 — Competitive Integrity
Client devices must never be trusted as the final authority for competitive results. Server-authoritative validation is mandatory for ranked and leaderboard-sensitive results.

---

# 4. GAME MODES

## 4.1 RANKED 1V1
- **Objective:** Defeat another player with a similar skill rating.
- **Match Length:** Best of 7 rounds (first to 4 wins early termination).
- **Match Flow:** Queue $\to$ Match Found $\to$ 1.5s Prep $\to$ Active Round $\to$ Independent Submission $\to$ Server Recalculation $\to$ Split Reveal $\to$ Settled $\to$ MMR Settlement.

## 4.2 DAILY CHALLENGE
- **Objective:** Compete against the entire player population on the exact same challenge sequence.
- **Structure:** 10 universal deterministic rounds.
- **Attempt Rule:** Exactly **ONE OFFICIAL ATTEMPT** per daily UTC cycle.
- **Reset:** 00:00:00 UTC (Server authoritative).
- **Resumption:** Resumable within the same UTC day; active rounds lock on pause to prevent cheat exploits.
- **Leaderboards:** Global Leaderboard ranked by `total_score DESC`, then `submitted_at ASC`.

---

# 5. THE 3 MVP CHALLENGES

1. **REACTION (Visual Reaction):** React to a visual color trigger as fast as possible. Measured in milliseconds ($t_{\text{rx}}$). Lower is better.
2. **MEMORY (Spatial Sequence Reproduction):** Memorize and reproduce an illuminated sequence on a $3 \times 3$ grid. Measured by correct cells reproduced and completion time.
3. **PRECISION (Target Accuracy):** Tap as close as possible to the center of a rapidly shrinking target in a $1:1$ square arena. Measured in normalized distance error ($d$) and tap offset ($\Delta t$).

---

# 6. SIGNATURE SPLIT COMPARISON CARD

Every challenge result uses a horizontally split comparison card:

```text
┌────────────────────────────────────────────────────────┐
│                        ROUND 3                         │
│                    VISUAL REACTION                     │
├────────────────────────────────────────────────────────┤
│                                                        │
│                          YOU                           │
│                         214 ms                         │
│                       [ 842 PTS ]                      │
│                                                        │
├────────────────────────────────────────────────────────┤
│                                                        │
│                       OPPONENT                         │
│                         249 ms                         │
│                       [ 710 PTS ]                      │
│                                                        │
├────────────────────────────────────────────────────────┤
│                       YOU WIN!                         │
└────────────────────────────────────────────────────────┘
```

The card animates into place: player result $\to$ opponent result $\to$ winner outcome banner. This generates the core competitive tension.

---

# 7. NON-NEGOTIABLE PRODUCT RULES

1. **Skill must determine competition.**
2. **Competitive results must be server-authoritative.**
3. **Both players receive equivalent challenge conditions.**
4. **No pay-to-win mechanics.**
5. **The player must understand why they won or lost.**
6. **The game must remain fun with only three challenges.**
7. **Do not add features to compensate for weak core gameplay.**
8. **Procedural generation via deterministic PRNG is mandatory.**
9. **Daily Challenge is one official attempt per cycle.**
10. **MMR represents competitive success, not raw mini-game scores.**
