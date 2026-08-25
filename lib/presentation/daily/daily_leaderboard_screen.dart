import 'package:flutter/material.dart';
import '../../core/routing/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/daily/daily_challenge_repository.dart';
import '../../domain/daily/daily_user_rank_summary.dart';
import '../../domain/daily/local_daily_challenge_repository.dart';
import 'widgets/daily_countdown_timer.dart';
import 'widgets/daily_nearby_list.dart';

class DailyLeaderboardScreen extends StatefulWidget {
  final DailyChallengeRepository? repository;

  const DailyLeaderboardScreen({
    super.key,
    this.repository,
  });

  @override
  State<DailyLeaderboardScreen> createState() => _DailyLeaderboardScreenState();
}

class _DailyLeaderboardScreenState extends State<DailyLeaderboardScreen> {
  late final DailyChallengeRepository _repository;
  Future<DailyUserRankSummary>? _rankFuture;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? LocalDailyChallengeRepository();
    _loadSummary();
  }

  void _loadSummary() {
    setState(() {
      _rankFuture = _repository.getUserRank();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pushReplacementNamed(AppRoutes.home),
        ),
        title: Text(
          'GLOBAL LEADERBOARD',
          style: AppTypography.titleLarge.copyWith(letterSpacing: 2.0),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<DailyUserRankSummary>(
        future: _rankFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            );
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Failed to load leaderboard',
                    style: AppTypography.bodyMedium.copyWith(color: AppColors.loss),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadSummary,
                    child: const Text('RETRY'),
                  ),
                ],
              ),
            );
          }

          final summary = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Countdown Banner
                DailyCountdownTimer(initialDuration: summary.durationUntilNextChallenge),
                const SizedBox(height: 24),

                // Today's Score Card
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border: Border.all(color: AppColors.accent, width: 1.5),
                  ),
                  child: Column(
                    children: [
                      Text(
                        "TODAY'S SCORE",
                        style: AppTypography.badgeText.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${summary.todayScore}',
                        style: AppTypography.displayLarge.copyWith(
                          color: AppColors.accent,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Rank and Percentile Row
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          border: Border.all(color: AppColors.surfaceBorder),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'GLOBAL RANK',
                              style: AppTypography.badgeText.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '#${summary.globalRank}',
                              style: AppTypography.displayMedium.copyWith(
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          border: Border.all(color: AppColors.surfaceBorder),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'TOP PERCENTILE',
                              style: AppTypography.badgeText.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${summary.percentile.toStringAsFixed(1)}%',
                              style: AppTypography.displayMedium.copyWith(
                                color: AppColors.accent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Nearby Players List
                DailyNearbyList(entries: summary.nearbyPlayers),
                const SizedBox(height: 32),

                // Return to Home Action
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pushReplacementNamed(AppRoutes.home),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.surfaceBorder),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                  ),
                  child: Text(
                    'RETURN HOME',
                    style: AppTypography.badgeText.copyWith(fontSize: 14),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
