import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class PillBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  const PillBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      margin: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: bottomPadding > 0 ? bottomPadding : 16,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(36),
        border: Border.all(color: AppColors.surfaceBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(140),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: AppColors.primary.withAlpha(20),
            blurRadius: 10,
            spreadRadius: 0.5,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _PillNavItem(
            index: 0,
            currentIndex: currentIndex,
            label: 'ARENA',
            icon: Icons.bolt,
            onTap: () => onTabSelected(0),
          ),
          _PillNavItem(
            index: 1,
            currentIndex: currentIndex,
            label: 'DAILY',
            icon: Icons.calendar_today,
            onTap: () => onTabSelected(1),
          ),
          _PillNavItem(
            index: 2,
            currentIndex: currentIndex,
            label: 'PROFILE',
            icon: Icons.person,
            onTap: () => onTabSelected(2),
          ),
        ],
      ),
    );
  }
}

class _PillNavItem extends StatelessWidget {
  final int index;
  final int currentIndex;
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _PillNavItem({
    required this.index,
    required this.currentIndex,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = index == currentIndex;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 16 : 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withAlpha(35)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: isSelected ? 18 : 16,
              color: isSelected ? AppColors.primary : AppColors.textMuted,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTypography.badgeText.copyWith(
                color: isSelected ? AppColors.primary : AppColors.textMuted,
                fontSize: 10,
                letterSpacing: 1.0,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
