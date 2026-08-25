import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../domain/daily/daily_leaderboard_entry.dart';

class DailyNearbyList extends StatelessWidget {
  final List<DailyLeaderboardEntry> entries;

  const DailyNearbyList({
    super.key,
    required this.entries,
  });

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'NEARBY PLAYERS',
          style: AppTypography.badgeText.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.surfaceBorder),
          ),
          child: Column(
            children: entries.map((entry) {
              final isUser = entry.isCurrentUser;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isUser ? AppColors.accent.withAlpha(30) : Colors.transparent,
                  border: Border(
                    bottom: BorderSide(
                      color: entry != entries.last ? AppColors.surfaceBorder : Colors.transparent,
                    ),
                    left: isUser
                        ? const BorderSide(color: AppColors.accent, width: 3)
                        : BorderSide.none,
                  ),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 54,
                      child: Text(
                        '#${entry.rank}',
                        style: AppTypography.titleMedium.copyWith(
                          color: isUser ? AppColors.accent : AppColors.textSecondary,
                          fontWeight: isUser ? FontWeight.w800 : FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        entry.displayName,
                        style: AppTypography.bodyLarge.copyWith(
                          color: isUser ? AppColors.textPrimary : AppColors.textSecondary,
                          fontWeight: isUser ? FontWeight.w700 : FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${entry.totalScore} pts',
                      style: AppTypography.titleMedium.copyWith(
                        color: isUser ? AppColors.accent : AppColors.textPrimary,
                        fontWeight: isUser ? FontWeight.w800 : FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
