import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../core/services/haptic_service.dart';
import '../../../domain/challenge/challenge_config.dart';
import '../../../domain/challenge/challenge_evidence.dart';

enum ReactionUiState { preparing, waiting, triggered, faulted, completed }

class ReactionRuntimeController extends ChangeNotifier {
  final ReactionConfig config;
  final void Function(ReactionEvidence evidence) onComplete;
  final int Function()? clockMonoMs;

  ReactionUiState _state = ReactionUiState.preparing;
  ReactionUiState get state => _state;

  final Stopwatch _stopwatch = Stopwatch();
  Timer? _prepTimer;
  Timer? _waitTimer;
  Timer? _timeoutTimer;

  int _triggerRenderedMonoMs = 0;
  int _touchDownMonoMs = 0;
  int _reactionTimeMs = 0;
  int get reactionTimeMs => _reactionTimeMs;

  ReactionRuntimeController({
    required this.config,
    required this.onComplete,
    this.clockMonoMs,
  });

  void start() {
    _state = ReactionUiState.preparing;
    notifyListeners();

    _prepTimer = Timer(const Duration(milliseconds: 800), () {
      _startWaiting();
    });
  }

  void _startWaiting() {
    _state = ReactionUiState.waiting;
    notifyListeners();

    _waitTimer = Timer(Duration(milliseconds: config.waitDelayMs), () {
      _triggerGo();
    });
  }

  int _getElapsedMs() {
    return clockMonoMs?.call() ?? _stopwatch.elapsedMilliseconds;
  }

  void _triggerGo() {
    _state = ReactionUiState.triggered;
    _stopwatch.reset();
    _stopwatch.start();
    _triggerRenderedMonoMs = _getElapsedMs();
    HapticService.lightImpact();
    notifyListeners();

    // 1000ms max timeout
    _timeoutTimer = Timer(const Duration(milliseconds: 1000), () {
      if (_state == ReactionUiState.triggered) {
        _handleTimeout();
      }
    });
  }

  void handleTap() {
    if (_state == ReactionUiState.waiting ||
        _state == ReactionUiState.preparing) {
      // Early tap / False start
      _waitTimer?.cancel();
      _prepTimer?.cancel();
      _timeoutTimer?.cancel();
      _state = ReactionUiState.faulted;
      _reactionTimeMs = 0;
      HapticService.heavyImpact();
      notifyListeners();

      final evidence = ReactionEvidence(
        clientTimestampMonoMs: DateTime.now().millisecondsSinceEpoch,
        reactionTimeMs: 0,
        isFault: true,
        triggerRenderedMonoMs: 0,
        touchDownMonoMs: 0,
      );
      onComplete(evidence);
    } else if (_state == ReactionUiState.triggered) {
      // Valid reaction tap
      _stopwatch.stop();
      _timeoutTimer?.cancel();
      _touchDownMonoMs = _getElapsedMs();
      _reactionTimeMs = _touchDownMonoMs - _triggerRenderedMonoMs;
      _state = ReactionUiState.completed;
      HapticService.mediumImpact();
      notifyListeners();

      final evidence = ReactionEvidence(
        clientTimestampMonoMs: DateTime.now().millisecondsSinceEpoch,
        reactionTimeMs: _reactionTimeMs,
        isFault: false,
        triggerRenderedMonoMs: _triggerRenderedMonoMs,
        touchDownMonoMs: _touchDownMonoMs,
      );
      onComplete(evidence);
    }
  }

  void _handleTimeout() {
    _stopwatch.stop();
    _state = ReactionUiState.completed;
    _reactionTimeMs = 1000;
    HapticService.vibrate();
    notifyListeners();

    final evidence = ReactionEvidence(
      clientTimestampMonoMs: DateTime.now().millisecondsSinceEpoch,
      reactionTimeMs: 1000,
      isFault: false,
      triggerRenderedMonoMs: _triggerRenderedMonoMs,
      touchDownMonoMs: _touchDownMonoMs,
    );
    onComplete(evidence);
  }

  @override
  void dispose() {
    _prepTimer?.cancel();
    _waitTimer?.cancel();
    _timeoutTimer?.cancel();
    _stopwatch.stop();
    super.dispose();
  }
}
