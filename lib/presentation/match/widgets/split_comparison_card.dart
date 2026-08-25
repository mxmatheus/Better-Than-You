import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/services/haptic_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../domain/match/match_state.dart';
import '../../../domain/match/round_result.dart';

class SplitComparisonCard extends StatefulWidget {
  final RoundResult roundResult;
  final VoidCallback onContinue;

  const SplitComparisonCard({
    super.key,
    required this.roundResult,
    required this.onContinue,
  });

  @override
  State<SplitComparisonCard> createState() => _SplitComparisonCardState();
}

class _SplitComparisonCardState extends State<SplitComparisonCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _cardSlideAnim;
  late final Animation<double> _playerScoreAnim;
  late final Animation<double> _oppScoreAnim;
  late final Animation<double> _outcomeScaleAnim;

  bool _showPlayer = false;
  bool _showOpponent = false;
  bool _showOutcome = false;
  bool _canContinue = false;

  final List<Timer> _choreographyTimers = [];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );

    _cardSlideAnim = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.15, curve: Curves.easeOutCubic),
    );

    _playerScoreAnim = Tween<double>(
      begin: 0,
      end: widget.roundResult.playerResult.normalizedScore.toDouble(),
    ).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.125, 0.35, curve: Curves.easeOut),
      ),
    );

    _oppScoreAnim = Tween<double>(
      begin: 0,
      end: widget.roundResult.opponentResult.normalizedScore.toDouble(),
    ).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.375, 0.60, curve: Curves.easeOut),
      ),
    );

    _outcomeScaleAnim = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.75, 0.85, curve: Curves.elasticOut),
    );

    _startChoreography();
    _animController.forward();
  }

  void _startChoreography() {
    // t = 0.4s: YOU section reveals
    _choreographyTimers.add(Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      setState(() => _showPlayer = true);
      HapticService.lightImpact();
    }));

    // t = 1.2s: Opponent section reveals
    _choreographyTimers.add(Timer(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      setState(() => _showOpponent = true);
      HapticService.lightImpact();
    }));

    // t = 2.4s: Outcome banner slams in
    _choreographyTimers.add(Timer(const Duration(milliseconds: 2400), () {
      if (!mounted) return;
      setState(() => _showOutcome = true);
      HapticService.heavyImpact();
    }));

    // t = 3.2s: Continue button becomes available
    _choreographyTimers.add(Timer(const Duration(milliseconds: 3200), () {
      if (!mounted) return;
      setState(() => _canContinue = true);
    }));
  }

  @override
  void dispose() {
    for (final timer in _choreographyTimers) {
      timer.cancel();
    }
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final outcome = widget.roundResult.outcome;
    Color outcomeColor;
    switch (outcome) {
      case RoundOutcome.win:
        outcomeColor = AppColors.win;
        break;
      case RoundOutcome.loss:
        outcomeColor = AppColors.loss;
        break;
      case RoundOutcome.draw:
        outcomeColor = AppColors.draw;
        break;
    }

    return FadeTransition(
      opacity: _cardSlideAnim,
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24.0),
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.surfaceBorder, width: 2.0),
            boxShadow: const [
              BoxShadow(
                color: Colors.black54,
                blurRadius: 24,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: const BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                  border: Border(
                    bottom: BorderSide(color: AppColors.surfaceBorder, width: 1.5),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'ROUND ${widget.roundResult.roundIndex}',
                      style: AppTypography.badgeText.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.roundResult.challengeType.displayName,
                      style: AppTypography.titleMedium.copyWith(
                        letterSpacing: 2.0,
                      ),
                    ),
                  ],
                ),
              ),

              // Player (YOU) Section
              _buildParticipantSection(
                label: 'YOU',
                metric: widget.roundResult.playerResult.formattedMetric,
                scoreAnim: _playerScoreAnim,
                color: AppColors.win,
                isVisible: _showPlayer,
              ),

              // Horizontal Split Divider
              Container(
                height: 2,
                color: _showOutcome ? outcomeColor : AppColors.surfaceBorder,
              ),

              // Opponent Section
              _buildParticipantSection(
                label: 'OPPONENT',
                metric: widget.roundResult.opponentResult.formattedMetric,
                scoreAnim: _oppScoreAnim,
                color: AppColors.opponent,
                isVisible: _showOpponent,
              ),

              // Outcome Banner (YOU WIN / YOU LOSE / DRAW)
              if (_showOutcome)
                ScaleTransition(
                  scale: _outcomeScaleAnim,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: outcomeColor.withAlpha(30),
                      border: Border(
                        top: BorderSide(color: outcomeColor, width: 1.5),
                        bottom:
                            BorderSide(color: AppColors.surfaceBorder, width: 1.5),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        outcome.displayName,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 3.0,
                          color: outcomeColor,
                        ),
                      ),
                    ),
                  ),
                ),

              // Continue Action Button
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: AnimatedOpacity(
                  opacity: _canContinue ? 1.0 : 0.2,
                  duration: const Duration(milliseconds: 200),
                  child: ElevatedButton(
                    onPressed: _canContinue ? widget.onContinue : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: outcomeColor,
                      foregroundColor: AppColors.background,
                    ),
                    child: const Text('CONTINUE'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildParticipantSection({
    required String label,
    required String metric,
    required Animation<double> scoreAnim,
    required Color color,
    required bool isVisible,
  }) {
    return AnimatedOpacity(
      opacity: isVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 20.0),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 2.0,
                color: color.withAlpha(200),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              metric,
              style: AppTypography.displayMedium.copyWith(
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 6),
            AnimatedBuilder(
              animation: scoreAnim,
              builder: (context, _) {
                return Text(
                  '${scoreAnim.value.round()} PTS',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'monospace',
                    letterSpacing: 1.5,
                    color: color,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
