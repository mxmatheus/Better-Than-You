import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../domain/match/match_session.dart';

class MatchHud extends StatelessWidget {
  final MatchSession session;

  const MatchHud({
    super.key,
    required this.session,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(
          bottom: BorderSide(color: AppColors.surfaceBorder, width: 1.5),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Round Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppColors.surfaceBorderLight, width: 1),
              ),
              child: Text(
                'ROUND ${session.currentRoundIndex} / ${session.totalRounds}',
                style: AppTypography.badgeText.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ),

            // Match Score: YOU vs OPPONENT
            Row(
              children: [
                _buildPlayerScore('YOU', session.playerWins, AppColors.win),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Text(
                    ':',
                    style: AppTypography.titleLarge.copyWith(
                      color: AppColors.surfaceBorderLight,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                _buildPlayerScore('OPPONENT', session.opponentWins, AppColors.opponent),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerScore(String label, int score, Color color) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
            color: color.withAlpha(200),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$score',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            fontFamily: 'monospace',
            color: color,
          ),
        ),
      ],
    );
  }
}
