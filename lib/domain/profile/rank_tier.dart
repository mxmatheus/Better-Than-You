import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

enum RankTier {
  bronze(0, 799, 'BRONZE', Color(0xFFCD7F32)),
  silver(800, 999, 'SILVER', Color(0xFFC0C0C0)),
  gold(1000, 1199, 'GOLD', Color(0xFFFFD700)),
  platinum(1200, 1399, 'PLATINUM', Color(0xFF00E5FF)),
  diamond(1400, 1599, 'DIAMOND', Color(0xFFB388FF)),
  master(1600, 1799, 'MASTER', Color(0xFFFF5252)),
  grandmaster(1800, 9999, 'GRANDMASTER', AppColors.primary);

  final int minMmr;
  final int maxMmr;
  final String label;
  final Color color;

  const RankTier(this.minMmr, this.maxMmr, this.label, this.color);

  static RankTier fromMmr(int mmr) {
    for (final tier in RankTier.values) {
      if (mmr >= tier.minMmr && mmr <= tier.maxMmr) {
        return tier;
      }
    }
    return RankTier.bronze;
  }

  String divisionString(int mmr) {
    if (this == grandmaster) return 'GRANDMASTER';
    final span = (maxMmr - minMmr + 1) ~/ 3;
    final offset = mmr - minMmr;
    if (offset < span) return '$label III';
    if (offset < span * 2) return '$label II';
    return '$label I';
  }
}
