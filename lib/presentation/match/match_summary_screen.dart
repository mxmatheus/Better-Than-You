import 'package:flutter/material.dart';
import '../../core/routing/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/match/match_session.dart';
import '../../domain/match/match_state.dart';

class MatchSummaryScreen extends StatelessWidget {
  final MatchSession session;

  const MatchSummaryScreen({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    final winner = session.overallWinner ?? RoundOutcome.draw;

    Color outcomeColor;
    String outcomeTitle;

    switch (winner) {
      case RoundOutcome.win:
        outcomeColor = AppColors.win;
        outcomeTitle = 'VICTORY';
        break;
      case RoundOutcome.loss:
        outcomeColor = AppColors.loss;
        outcomeTitle = 'DEFEAT';
        break;
      case RoundOutcome.draw:
        outcomeColor = AppColors.draw;
        outcomeTitle = 'DRAW';
        break;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              // Outcome Banner
              Center(
                child: Text(
                  outcomeTitle,
                  style: AppTypography.displayLarge.copyWith(
                    color: outcomeColor,
                    letterSpacing: 4.0,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Match Score
              Center(
                child: Text(
                  '${session.playerWins} — ${session.opponentWins}',
                  style: AppTypography.scoreNumber.copyWith(
                    fontSize: 44,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Round-by-Round History Card
              Text(
                'ROUND RECAP',
                style: AppTypography.titleMedium.copyWith(
                  letterSpacing: 1.5,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  itemCount: session.history.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = session.history[index];
                    final isWin = item.outcome == RoundOutcome.win;
                    final isLoss = item.outcome == RoundOutcome.loss;
                    final color = isWin
                        ? AppColors.win
                        : (isLoss ? AppColors.loss : AppColors.draw);

                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppColors.surfaceBorder,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                'R${item.roundIndex}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontFamily: 'monospace',
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                item.challengeType.displayName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Text(
                                '${item.playerResult.normalizedScore} pts',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontFamily: 'monospace',
                                  color: color,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: color.withAlpha(40),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: Text(
                                  item.outcome.displayName,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    color: color,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Action Buttons
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushReplacementNamed(AppRoutes.match);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.background,
                ),
                child: const Text('REMATCH'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () {
                  Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(
                    color: AppColors.surfaceBorder,
                    width: 1.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: const Text(
                  'EXIT TO HOME',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
