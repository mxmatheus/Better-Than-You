import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../domain/challenge/challenge_config.dart';
import '../../../domain/challenge/challenge_evidence.dart';
import '../controllers/memory_runtime_controller.dart';

class MemoryChallengeWidget extends StatefulWidget {
  final MemoryConfig config;
  final void Function(MemoryEvidence evidence) onComplete;

  const MemoryChallengeWidget({
    super.key,
    required this.config,
    required this.onComplete,
  });

  @override
  State<MemoryChallengeWidget> createState() => _MemoryChallengeWidgetState();
}

class _MemoryChallengeWidgetState extends State<MemoryChallengeWidget> {
  late final MemoryRuntimeController _controller;

  @override
  void initState() {
    super.initState();
    _controller = MemoryRuntimeController(
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

        String headerText;
        String subText;

        switch (state) {
          case MemoryUiState.preparing:
            headerText = 'GET READY';
            subText = 'Watch the pattern closely';
            break;
          case MemoryUiState.playback:
            headerText = 'WATCH PATTERN';
            subText = 'Sequence length: ${widget.config.sequenceLength}';
            break;
          case MemoryUiState.inputMode:
            headerText = 'REPRODUCE';
            subText =
                'Progress: ${_controller.userProgressIndex} / ${widget.config.sequenceLength}';
            break;
          case MemoryUiState.failed:
            headerText = 'WRONG TILE!';
            subText =
                'Completed: ${_controller.userProgressIndex} / ${widget.config.sequenceLength}';
            break;
          case MemoryUiState.completed:
            headerText = 'COMPLETED!';
            subText =
                '${_controller.userProgressIndex} / ${widget.config.sequenceLength} reproduced';
            break;
        }

        return Container(
          color: AppColors.background,
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                headerText,
                style: AppTypography.titleLarge.copyWith(
                  color: state == MemoryUiState.failed
                      ? AppColors.loss
                      : (state == MemoryUiState.inputMode
                          ? AppColors.primary
                          : AppColors.textPrimary),
                  fontSize: 26,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subText,
                style: AppTypography.bodyMedium,
              ),
              const SizedBox(height: 16),

              // 3x3 Grid centered in a constrained square
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1.0,
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 340, maxHeight: 340),
                      child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                      ),
                      itemCount: 9,
                      itemBuilder: (context, index) {
                        final isIlluminated =
                            _controller.activeTileIndex == index;
                        final isFailed = _controller.failedTileIndex == index;

                        Color tileColor = AppColors.surface;
                        Color borderColor = AppColors.surfaceBorder;

                        if (isFailed) {
                          tileColor = AppColors.loss;
                          borderColor = AppColors.loss;
                        } else if (isIlluminated) {
                          tileColor = AppColors.win;
                          borderColor = AppColors.win;
                        }

                        return GestureDetector(
                          onTapDown: (_) => _controller.handleTileTap(index),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 120),
                            decoration: BoxDecoration(
                              color: tileColor,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: borderColor,
                                width: 2.0,
                              ),
                              boxShadow: isIlluminated
                                  ? [
                                      BoxShadow(
                                        color: AppColors.win.withAlpha(120),
                                        blurRadius: 16,
                                        spreadRadius: 2,
                                      )
                                    ]
                                  : null,
                            ),
                          ),
                        );
                      },
                      ),
                    ),
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
