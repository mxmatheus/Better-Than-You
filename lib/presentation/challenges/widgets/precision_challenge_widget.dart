import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../domain/challenge/challenge_config.dart';
import '../../../domain/challenge/challenge_evidence.dart';
import '../controllers/precision_runtime_controller.dart';

class PrecisionChallengeWidget extends StatefulWidget {
  final PrecisionConfig config;
  final void Function(PrecisionEvidence evidence) onComplete;

  const PrecisionChallengeWidget({
    super.key,
    required this.config,
    required this.onComplete,
  });

  @override
  State<PrecisionChallengeWidget> createState() =>
      _PrecisionChallengeWidgetState();
}

class _PrecisionChallengeWidgetState extends State<PrecisionChallengeWidget> {
  late final PrecisionRuntimeController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PrecisionRuntimeController(
      config: widget.config,
      onComplete: widget.onComplete,
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

        String title;
        String subtitle;

        switch (state) {
          case PrecisionUiState.preparing:
            title = 'GET READY';
            subtitle = 'Tap the center of the target';
            break;
          case PrecisionUiState.active:
            title = 'TAP TARGET';
            subtitle = 'Closer to center = higher score';
            break;
          case PrecisionUiState.hit:
            title = 'HIT!';
            subtitle = 'Processing accuracy';
            break;
          case PrecisionUiState.missed:
            title = 'MISSED!';
            subtitle = 'Outside target boundary';
            break;
          case PrecisionUiState.timeout:
            title = 'TOO SLOW!';
            subtitle = 'Target expired';
            break;
        }

        return Container(
          color: AppColors.background,
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: AppTypography.titleLarge.copyWith(
                  color: state == PrecisionUiState.hit
                      ? AppColors.win
                      : (state == PrecisionUiState.missed ||
                              state == PrecisionUiState.timeout
                          ? AppColors.loss
                          : AppColors.primary),
                  fontSize: 26,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: AppTypography.bodyMedium,
              ),
              const SizedBox(height: 16),

              // 1:1 Square Arena fitted inside available space
              Expanded(
                child: Center(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final arenaSize = math
                          .min(constraints.maxWidth, constraints.maxHeight)
                          .clamp(0.0, 360.0);

                      return SizedBox(
                        width: arenaSize,
                        height: arenaSize,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.surfaceBorder,
                              width: 2.0,
                            ),
                          ),
                          child: GestureDetector(
                            key: const Key('precision_arena'),
                            behavior: HitTestBehavior.opaque,
                            onTapDown: (details) {
                              final localPos = details.localPosition;
                              final xNorm =
                                  (localPos.dx / arenaSize).clamp(0.0, 1.0);
                              final yNorm =
                                  (localPos.dy / arenaSize).clamp(0.0, 1.0);
                              _controller.handleTap(xNorm, yNorm);
                            },
                            child: CustomPaint(
                              size: Size(arenaSize, arenaSize),
                              painter: _PrecisionTargetPainter(
                                config: widget.config,
                                shrinkProgress: _controller.shrinkProgress,
                                state: state,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PrecisionTargetPainter extends CustomPainter {
  final PrecisionConfig config;
  final double shrinkProgress;
  final PrecisionUiState state;

  const _PrecisionTargetPainter({
    required this.config,
    required this.shrinkProgress,
    required this.state,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (state == PrecisionUiState.preparing) {
      // Draw center preparation crosshair
      final centerPaint = Paint()
        ..color = AppColors.surfaceBorderLight
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      canvas.drawCircle(
        Offset(size.width / 2, size.height / 2),
        16,
        centerPaint,
      );
      return;
    }

    if (state == PrecisionUiState.timeout) return;

    final targetCenter = Offset(
      config.xTarget * size.width,
      config.yTarget * size.height,
    );

    // Radius shrinks from base radius to zero over the duration
    final baseRadius = config.radiusNorm * size.width;
    final currentRadius = baseRadius * (1.0 - shrinkProgress);

    if (currentRadius <= 1.0) return;

    Color ringColor = AppColors.primary;
    if (state == PrecisionUiState.hit) {
      ringColor = AppColors.win;
    } else if (state == PrecisionUiState.missed) {
      ringColor = AppColors.loss;
    }

    // Outer Target Circle
    final outerPaint = Paint()
      ..color = ringColor.withAlpha(40)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(targetCenter, currentRadius, outerPaint);

    final ringPaint = Paint()
      ..color = ringColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(targetCenter, currentRadius, ringPaint);

    // Inner Concentric Ring
    if (currentRadius > 8) {
      final innerPaint = Paint()
        ..color = ringColor.withAlpha(180)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(targetCenter, currentRadius * 0.5, innerPaint);
    }

    // Center Bullseye Dot
    final dotPaint = Paint()
      ..color = ringColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(targetCenter, 4.0, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _PrecisionTargetPainter oldDelegate) {
    return oldDelegate.shrinkProgress != shrinkProgress ||
        oldDelegate.state != state;
  }
}
