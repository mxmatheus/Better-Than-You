import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/auth/auth_repository.dart';
import '../../domain/daily/daily_challenge_repository.dart';
import '../../domain/match/match_repository.dart';
import '../daily/daily_challenge_screen.dart';
import '../home/home_screen.dart';
import '../profile/profile_screen.dart';
import 'widgets/pill_bottom_navigation_bar.dart';

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
      HomeScreen(
        matchRepository: widget.matchRepository,
        authRepository: widget.authRepository,
      ),
      DailyChallengeScreen(repository: widget.dailyRepository),
      ProfileScreen(authRepository: widget.authRepository),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: PillBottomNavigationBar(
        currentIndex: _currentIndex,
        onTabSelected: (idx) => setState(() => _currentIndex = idx),
      ),
    );
  }
}
