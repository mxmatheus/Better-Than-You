enum MatchLifecycleState {
  matchmaking,
  matchFound,
  ready,
  roundPreparing,
  roundActive,
  waitingForSubmissions,
  validating,
  roundResult,
  nextRound,
  matchCompleted,
  settling,
  settled,
  abandoned;

  bool get isActiveRound => this == roundActive;
  bool get isRevealCard => this == roundResult;
  bool get isMatchOver => this == settled || this == abandoned;
}

enum RoundOutcome {
  win,
  loss,
  draw;

  String get displayName {
    switch (this) {
      case RoundOutcome.win:
        return 'YOU WIN';
      case RoundOutcome.loss:
        return 'YOU LOSE';
      case RoundOutcome.draw:
        return 'DRAW';
    }
  }
}
