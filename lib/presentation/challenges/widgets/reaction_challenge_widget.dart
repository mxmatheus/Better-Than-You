import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../domain/challenge/challenge_config.dart';
import '../../../domain/challenge/challenge_evidence.dart';
import '../controllers/reaction_runtime_controller.dart';

class ReactionChallengeWidget extends StatefulWidget {
  final ReactionConfig config;
  final void Function(ReactionEvidence evidence) onComplete;
  final int Function()? clockMonoMs;

  const ReactionChallengeWidget({
    super.key,
    required this.config,
    required this.onComplete,
    this.clockMonoMs,
  });

  @override
  State<ReactionChallengeWidget> createState() =>
      _ReactionChallengeWidgetState();
}

class _ReactionChallengeWidgetState extends State<ReactionChallengeWidget> {
  late final ReactionRuntimeController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ReactionRuntimeController(
      config: widget.config,
      onComplete: widget.onComplete,
      clockMonoMs: widget.clockMonoMs,
    );
    _controller.start();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final state = _controller.state;

        Color bgColor;
        String mainText;
        String subText;

        switch (state) {
          case ReactionUiState.preparing:
            bgColor = AppColors.background;
            mainText = 'GET READY';
            subText = 'Tap as soon as the screen turns green';
            break;
          case ReactionUiState.waiting:
            bgColor = AppColors.background;
            mainText = 'WAIT...';
            subText = 'Do not tap yet';
            break;
          case ReactionUiState.triggered:
            bgColor = AppColors.win;
            mainText = 'TAP!';
            subText = 'NOW!';
            break;
          case ReactionUiState.faulted:
            bgColor = AppColors.loss;
            mainText = 'TOO EARLY!';
            subText = 'False start recorded';
            break;
          case ReactionUiState.completed:
            bgColor = AppColors.surface;
            mainText = '${_controller.reactionTimeMs} ms';
            subText = 'Recorded';
            break;
        }

        final isTriggered = state == ReactionUiState.triggered;
        final textColor = isTriggered
            ? AppColors.background
            : AppColors.textPrimary;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => _controller.handleTap(),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            color: bgColor,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    mainText,
                    style: AppTypography.displayLarge.copyWith(
                      color: textColor,
                      fontSize: state == ReactionUiState.triggered ? 64 : 44,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    subText,
                    style: AppTypography.titleMedium.copyWith(
                      color: isTriggered
                          ? AppColors.background.withAlpha(200)
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
