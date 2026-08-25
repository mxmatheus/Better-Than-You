import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/auth/auth_repository.dart';
import '../../domain/daily/daily_challenge_repository.dart';
import '../../domain/match/match_repository.dart';
import '../daily/daily_challenge_screen.dart';
import '../home/home_screen.dart';
import '../profile/profile_screen.dart';

class AppShell extends StatefulWidget {
  final int initialTab;
  final AuthRepository? authRepository;
  final MatchRepository? matchRepository;
  final DailyChallengeRepository? dailyRepository;

  const AppShell({
    super.key,
    this.initialTab = 0,
    this.authRepository,
    this.matchRepository,
    this.dailyRepository,
  });

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab;
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(matchRepository: widget.matchRepository),
      DailyChallengeScreen(repository: widget.dailyRepository),
      ProfileScreen(authRepository: widget.authRepository),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(color: AppColors.surfaceBorder, width: 1.0),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (idx) => setState(() => _currentIndex = idx),
          backgroundColor: AppColors.surface,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textMuted,
          selectedLabelStyle: AppTypography.badgeText.copyWith(fontSize: 10),
          unselectedLabelStyle: AppTypography.badgeText.copyWith(fontSize: 10),
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.flash_on, size: 22),
              activeIcon: Icon(
                Icons.flash_on,
                size: 22,
                color: AppColors.primary,
              ),
              label: 'ARENA',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today, size: 20),
              activeIcon: Icon(
                Icons.calendar_today,
                size: 20,
                color: AppColors.primary,
              ),
              label: 'DAILY',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline, size: 22),
              activeIcon: Icon(
                Icons.person,
                size: 22,
                color: AppColors.primary,
              ),
              label: 'PROFILE',
            ),
          ],
        ),
      ),
    );
  }
}
