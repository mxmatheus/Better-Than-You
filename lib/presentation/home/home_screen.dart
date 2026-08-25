import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/routing/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/auth/auth_repository.dart';
import '../../domain/auth/auth_state.dart';
import '../../domain/match/match_repository.dart';
import '../../domain/profile/player_profile.dart';

class HomeScreen extends StatefulWidget {
  final MatchRepository? matchRepository;
  final AuthRepository? authRepository;

  const HomeScreen({super.key, this.matchRepository, this.authRepository});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  StreamSubscription<AppAuthState>? _authSubscription;
  PlayerProfile _profile = const PlayerProfile(
    id: 'guest_001',
    username: 'CHALLENGER',
    displayName: 'CHALLENGER',
    mmr: 1000,
    matchesPlayed: 0,
    wins: 0,
    losses: 0,
  );

  @override
  void initState() {
    super.initState();
    if (widget.authRepository != null) {
      final state = widget.authRepository!.currentState;
      if (state is AuthAuthenticated) {
        _profile = state.profile;
      }
      _authSubscription = widget.authRepository!.authStateChanges.listen((s) {
        if (s is AuthAuthenticated && mounted) {
          setState(() => _profile = s.profile);
        }
      });
      _loadProfile();
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final p = await widget.authRepository?.getProfile();
    if (p != null && mounted) {
      setState(() => _profile = p);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(
            left: 20.0,
            right: 20.0,
            top: 16.0,
            bottom: 96.0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Profile & MMR Bar
              _buildTopBar(),
              const SizedBox(height: 24),

              // Hero Title
              const Text('BETTER\nTHAN YOU', style: AppTypography.displayLarge),
              const SizedBox(height: 8),
              Text(
                'PROVE IT.',
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.primary,
                  letterSpacing: 3.0,
                ),
              ),
              const SizedBox(height: 24),

              // Ranked Play CTA Card
              _buildRankedCard(),
              const SizedBox(height: 16),

              // Daily Challenge Card
              _buildDailyCard(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.surfaceBorder, width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(_profile.displayName, style: AppTypography.titleMedium),
            ],
          ),
          Row(
            children: [
              Text(
                '${_profile.mmr} MMR',
                style: AppTypography.badgeText.copyWith(
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _profile.rankTier.color.withAlpha(40),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: _profile.rankTier.color, width: 1),
                ),
                child: Text(
                  _profile.rankDivision,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: _profile.rankTier.color,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRankedCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary, width: 1.5),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            Navigator.of(context).pushNamed(AppRoutes.match);
          },
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'RANKED 1V1',
                      style: AppTypography.titleLarge.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                    const Icon(Icons.bolt, color: AppColors.primary, size: 24),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Best of 7 deterministic skill rounds. Affects MMR.',
                  style: AppTypography.bodyMedium,
                ),
                const SizedBox(height: 16),
                Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'FIND OPPONENT',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: AppColors.background,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDailyCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.surfaceBorder, width: 1.5),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            Navigator.of(context).pushNamed(AppRoutes.daily);
          },
          child: const Padding(
            padding: EdgeInsets.all(20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('DAILY CHALLENGE', style: AppTypography.titleMedium),
                    SizedBox(height: 4),
                    Text(
                      '10 universal rounds. 1 official attempt.',
                      style: AppTypography.bodyMedium,
                    ),
                  ],
                ),
                Icon(
                  Icons.leaderboard,
                  color: AppColors.textSecondary,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
