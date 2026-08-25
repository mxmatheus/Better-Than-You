# BETTER THAN YOU

BETTER THAN YOU is a competitive mobile skill game where players face off in short reaction, memory, and precision challenges.

## What is it?

The game is built around fast, skill-based 1v1 competition:

- **1v1 Skill Challenges:** Both players receive the exact same deterministic challenge conditions.
- **Blind Rounds:** You don't see your opponent's actions or progress while playing a round.
- **Split Reveal:** At the end of each round, a split comparison card reveals both players' metrics and determines the winner.
- **Ranked Matchmaking:** Compete in short Best-of-7 matches that affect your competitive rating (MMR).
- **Daily Challenge:** A universal 10-round challenge where every player gets one official attempt each day to climb the global leaderboard.
- **Quick Sessions:** Individual rounds take only a few seconds, keeping matches fast and intense.

## Current Challenges

- **Reaction:** React to a visual trigger as quickly as possible upon appearance.
- **Memory:** Memorize and reproduce a sequential pattern on a grid.
- **Precision:** Tap as close as possible to the center of a shrinking target.

## Tech Stack

- **Client:** Flutter / Dart (Android)
- **Backend:** Supabase (Auth, Edge Functions, Realtime)
- **Database:** PostgreSQL
- **RNG:** Mulberry32 deterministic generator

## Project Structure

```text
lib/
  core/         # Theme, routing, constants
  features/     # UI screens, widgets, controllers
  shared/       # Reusable components and utilities
test/           # Unit and widget tests
docs/           # Design notes and specifications
```

## Development

Get dependencies:
```bash
flutter pub get
```

Run static analysis:
```bash
flutter analyze
```

Run tests:
```bash
flutter test
```

Run the app:
```bash
flutter run
```

## Status

- [x] Project setup
- [x] Core architecture
- [x] Visual foundation
- [ ] Challenge engine
- [ ] Ranked multiplayer
- [ ] Daily challenge
- [ ] Leaderboards
- [ ] Release build

## License

Private project — all rights reserved.
