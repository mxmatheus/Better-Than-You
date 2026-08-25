import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/routing/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/auth/auth_repository.dart';
import '../../domain/auth/auth_state.dart';
import '../../domain/auth/local_auth_repository.dart';
import '../../domain/profile/player_profile.dart';

class ProfileScreen extends StatefulWidget {
  final AuthRepository? authRepository;
  final PlayerProfile? initialProfile;

  const ProfileScreen({super.key, this.authRepository, this.initialProfile});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final AuthRepository _authRepository;
  StreamSubscription<AppAuthState>? _authSubscription;
  PlayerProfile? _profile;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _authRepository = widget.authRepository ?? LocalAuthRepository();

    if (widget.initialProfile != null) {
      _profile = widget.initialProfile;
    } else if (_authRepository.currentState is AuthAuthenticated) {
      _profile = (_authRepository.currentState as AuthAuthenticated).profile;
    }

    _authSubscription = _authRepository.authStateChanges.listen((state) {
      if (state is AuthAuthenticated && mounted) {
        setState(() => _profile = state.profile);
      }
    });

    if (_profile == null) {
      _loadProfile();
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    final p = await _authRepository.getProfile();
    if (mounted) {
      setState(() {
        if (p != null) {
          _profile = p;
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _handleLogout() async {
    await _authRepository.signOut();
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
  }

  Future<void> _showEditDisplayNameDialog() async {
    if (_profile == null) return;
    final controller = TextEditingController(text: _profile!.displayName);

    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: AppColors.surfaceBorder),
          borderRadius: BorderRadius.circular(4),
        ),
        title: Text(
          'EDIT DISPLAY NAME',
          style: AppTypography.titleMedium.copyWith(color: AppColors.primary),
        ),
        content: TextField(
          controller: controller,
          style: AppTypography.bodyLarge.copyWith(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Enter new display name',
            hintStyle: AppTypography.bodyMedium.copyWith(
              color: AppColors.textMuted,
            ),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.surfaceBorder),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.primary),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'CANCEL',
              style: AppTypography.badgeText.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.background,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            child: Text(
              'SAVE',
              style: AppTypography.badgeText.copyWith(
                color: AppColors.background,
              ),
            ),
          ),
        ],
      ),
    );

    if (newName != null &&
        newName.isNotEmpty &&
        newName != _profile!.displayName) {
      try {
        final updated = await _authRepository.updateProfile(
          displayName: newName,
        );
        if (mounted) {
          setState(() => _profile = updated);
        }
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _profile == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    final p =
        _profile ??
        const PlayerProfile(
          id: 'user_001',
          username: 'Challenger',
          displayName: 'Challenger',
          mmr: 1000,
        );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(
            left: 20.0,
            right: 20.0,
            top: 24.0,
            bottom: 96.0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header & Identity Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.surfaceBorder),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    // Avatar Circle
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.background,
                        border: Border.all(color: AppColors.primary, width: 2),
                      ),
                      child: Center(
                        child: Text(
                          p.username.isNotEmpty
                              ? p.username[0].toUpperCase()
                              : 'U',
                          style: AppTypography.titleLarge.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  p.displayName,
                                  style: AppTypography.titleMedium.copyWith(
                                    color: AppColors.textPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  size: 16,
                                  color: AppColors.textSecondary,
                                ),
                                onPressed: _showEditDisplayNameDialog,
                                tooltip: 'Edit Display Name',
                              ),
                            ],
                          ),
                          Text(
                            '@${p.username}',
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Competitive Rating Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.primary.withAlpha(80)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'RANK TIER',
                          style: AppTypography.badgeText.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withAlpha(30),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            p.rankDivision,
                            style: AppTypography.badgeText.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '${p.mmr}',
                          style: AppTypography.displayLarge.copyWith(
                            color: AppColors.primary,
                            fontSize: 48,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'MMR',
                          style: AppTypography.titleMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    if (p.isProvisional) ...[
                      const SizedBox(height: 8),
                      Text(
                        'PROVISIONAL: ${p.provisionalMatchesRemaining} MATCHES REMAINING',
                        style: AppTypography.badgeText.copyWith(
                          color: AppColors.accent,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Statistics Grid
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.surfaceBorder),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MATCH RECORD',
                      style: AppTypography.badgeText.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _StatItem(label: 'PLAYED', value: '${p.matchesPlayed}'),
                        _StatItem(
                          label: 'WINS',
                          value: '${p.wins}',
                          color: AppColors.win,
                        ),
                        _StatItem(
                          label: 'LOSSES',
                          value: '${p.losses}',
                          color: AppColors.loss,
                        ),
                        _StatItem(label: 'DRAWS', value: '${p.draws}'),
                        _StatItem(
                          label: 'WIN RATE',
                          value: '${p.winRate.toStringAsFixed(1)}%',
                        ),
                      ],
                    ),
                    const Divider(color: AppColors.surfaceBorder, height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'STRONGEST ATTRIBUTE',
                              style: AppTypography.badgeText.copyWith(
                                color: AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              p.strongestSkill,
                              style: AppTypography.titleMedium.copyWith(
                                color: AppColors.win,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'WEAKEST ATTRIBUTE',
                              style: AppTypography.badgeText.copyWith(
                                color: AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              p.weakSkill,
                              style: AppTypography.titleMedium.copyWith(
                                color: AppColors.loss,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Logout Button
              OutlinedButton.icon(
                onPressed: _handleLogout,
                icon: const Icon(Icons.logout, size: 18, color: AppColors.loss),
                label: Text(
                  'LOGOUT',
                  style: AppTypography.badgeText.copyWith(
                    color: AppColors.loss,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.loss),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _StatItem({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: AppTypography.titleMedium.copyWith(
            color: color ?? AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTypography.badgeText.copyWith(
            color: AppColors.textMuted,
            fontSize: 9,
          ),
        ),
      ],
    );
  }
}
