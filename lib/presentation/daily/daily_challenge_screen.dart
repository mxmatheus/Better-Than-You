import 'package:flutter/material.dart';
import '../../core/routing/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/mulberry32.dart';
import '../../domain/challenge/challenge_evidence.dart';
import '../../domain/challenge/challenge_registry.dart';
import '../../domain/challenge/challenge_result.dart';
import '../../domain/challenge/challenge_type.dart';
import '../../domain/daily/daily_challenge.dart';
import '../../domain/daily/daily_challenge_repository.dart';
import '../../domain/daily/daily_submission.dart';
import '../../domain/daily/local_daily_challenge_repository.dart';
import '../challenges/widgets/memory_challenge_widget.dart';
import '../challenges/widgets/precision_challenge_widget.dart';
import '../challenges/widgets/reaction_challenge_widget.dart';

class DailyChallengeScreen extends StatefulWidget {
  final DailyChallengeRepository? repository;

  const DailyChallengeScreen({super.key, this.repository});

  @override
  State<DailyChallengeScreen> createState() => _DailyChallengeScreenState();
}

class _DailyChallengeScreenState extends State<DailyChallengeScreen> {
  late final DailyChallengeRepository _repository;

  bool _isLoading = true;
  DailyChallenge? _challenge;
  DailySubmission? _submission;
  int _currentRoundIndex = 1;
  int _runningTotalScore = 0;
  bool _isRoundActive = false;
  ChallengeResult? _lastRoundResult;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? LocalDailyChallengeRepository();
    _initializeDaily();
  }

  Future<void> _initializeDaily() async {
    try {
      final challenge = await _repository.getDailyChallenge();
      final sub = await _repository.startOrResumeDailyChallenge();

      if (!mounted) return;

      setState(() {
        _challenge = challenge;
        _submission = sub;
        _currentRoundIndex = sub.currentRoundIndex;
        _runningTotalScore = sub.totalScore;
        _isLoading = false;
      });

      if (sub.isCompleted) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.dailyLeaderboard);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _startRound() {
    setState(() {
      _isRoundActive = true;
      _lastRoundResult = null;
    });
  }

  Future<void> _handleRoundCompletion(ChallengeEvidence evidence) async {
    if (_challenge == null) return;

    final result = await _repository.submitRoundEvidence(
      date: _challenge!.challengeDate,
      roundIndex: _currentRoundIndex,
      evidence: evidence,
    );

    if (!mounted) return;

    setState(() {
      _lastRoundResult = result;
      _runningTotalScore += result.normalizedScore;
      _isRoundActive = false;
    });

    // If 10 rounds completed, navigate to leaderboard
    if (_currentRoundIndex >= 10) {
      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.dailyLeaderboard);
      }
    } else {
      setState(() {
        _currentRoundIndex++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.accent)),
      );
    }

    if (_challenge == null || _submission == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Text(
            'Failed to load Daily Challenge',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.loss),
          ),
        ),
      );
    }

    final currentType = _challenge!.scheduledChallenges[_currentRoundIndex - 1];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.close,
            size: 20,
            color: AppColors.textSecondary,
          ),
          onPressed: () =>
              Navigator.of(context).pushReplacementNamed(AppRoutes.home),
        ),
        title: Text(
          'DAILY CHALLENGE',
          style: AppTypography.titleLarge.copyWith(letterSpacing: 2.0),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top HUD
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'ROUND $_currentRoundIndex / 10',
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'SCORE: $_runningTotalScore',
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: AppColors.surfaceBorder, height: 1),

            // Main Challenge Area
            Expanded(
              child: _isRoundActive
                  ? _buildActiveChallenge(currentType)
                  : _buildPreparationView(currentType),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreparationView(ChallengeType type) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(
        left: 24.0,
        right: 24.0,
        top: 24.0,
        bottom: 96.0,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_lastRoundResult != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: AppColors.accent),
              ),
              child: Column(
                children: [
                  Text(
                    'ROUND COMPLETED',
                    style: AppTypography.badgeText.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '+${_lastRoundResult!.normalizedScore} pts',
                    style: AppTypography.displayMedium.copyWith(
                      color: AppColors.accent,
                    ),
                  ),
                  Text(
                    _lastRoundResult!.formattedMetric,
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
          Text(
            type.displayName.toUpperCase(),
            style: AppTypography.displayMedium.copyWith(
              color: AppColors.textPrimary,
              letterSpacing: 3.0,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            _getInstructionsForType(type),
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          ElevatedButton(
            onPressed: _startRound,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: AppColors.background,
              padding: const EdgeInsets.symmetric(vertical: 20),
            ),
            child: Text(
              'START ROUND $_currentRoundIndex',
              style: AppTypography.badgeText.copyWith(
                color: AppColors.background,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveChallenge(ChallengeType type) {
    // Generate deterministic round seed from daily seed
    final prng = Mulberry32(_challenge!.seed);
    var roundSeed = _challenge!.seed;
    for (var i = 1; i <= _currentRoundIndex; i++) {
      roundSeed = prng.nextUint32();
    }

    final def = ChallengeRegistry.getDefinition(type);
    final config = def.generator.generate(roundSeed);

    switch (type) {
      case ChallengeType.reaction:
        return ReactionChallengeWidget(
          config: config as dynamic,
          onComplete: (evidence) => _handleRoundCompletion(evidence),
        );
      case ChallengeType.memory:
        return MemoryChallengeWidget(
          config: config as dynamic,
          onComplete: (evidence) => _handleRoundCompletion(evidence),
        );
      case ChallengeType.precision:
        return PrecisionChallengeWidget(
          config: config as dynamic,
          onComplete: (evidence) => _handleRoundCompletion(evidence),
        );
    }
  }

  String _getInstructionsForType(ChallengeType type) {
    switch (type) {
      case ChallengeType.reaction:
        return 'Tap the screen as fast as possible when the color changes. Early taps are penalized.';
      case ChallengeType.memory:
        return 'Memorize the highlighted tile sequence and repeat it accurately.';
      case ChallengeType.precision:
        return 'Tap as close to the target center as possible before the countdown timer expires.';
    }
  }
}
