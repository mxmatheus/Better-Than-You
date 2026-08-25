import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../../../core/services/haptic_service.dart';
import '../../../domain/challenge/challenge_config.dart';
import '../../../domain/challenge/challenge_evidence.dart';

enum PrecisionUiState {
  preparing,
  active,
  hit,
  missed,
  timeout,
}

class PrecisionRuntimeController extends ChangeNotifier {
  final PrecisionConfig config;
  final void Function(PrecisionEvidence evidence) onComplete;

  PrecisionUiState _state = PrecisionUiState.preparing;
  PrecisionUiState get state => _state;

  final Stopwatch _stopwatch = Stopwatch();
  Timer? _prepTimer;
  Timer? _timeoutTimer;

  double _shrinkProgress = 0.0; // 0.0 -> 1.0
  double get shrinkProgress => _shrinkProgress;

  Timer? _ticker;

  PrecisionRuntimeController({
    required this.config,
    required this.onComplete,
  });

  void start() {
    _state = PrecisionUiState.preparing;
    notifyListeners();

    _prepTimer = Timer(const Duration(milliseconds: 800), () {
      _startActive();
    });
  }

  void _startActive() {
    _state = PrecisionUiState.active;
    _stopwatch.reset();
    _stopwatch.start();
    HapticService.lightImpact();
    notifyListeners();

    // 60 FPS shrink ticker
    _ticker = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (_state != PrecisionUiState.active) {
        timer.cancel();
        return;
      }
      final elapsed = _stopwatch.elapsedMilliseconds;
      _shrinkProgress = (elapsed / config.durationMs).clamp(0.0, 1.0);
      notifyListeners();

      if (elapsed >= config.durationMs) {
        timer.cancel();
        _handleTimeout();
      }
    });
  }

  void handleTap(double xNorm, double yNorm) {
    if (_state != PrecisionUiState.active) return;

    _ticker?.cancel();
    _stopwatch.stop();
    final elapsed = _stopwatch.elapsedMilliseconds;

    final dx = xNorm - config.xTarget;
    final dy = yNorm - config.yTarget;
    final distance = math.sqrt(dx * dx + dy * dy);

    final isHit = distance <= config.radiusNorm;
    _state = isHit ? PrecisionUiState.hit : PrecisionUiState.missed;

    if (isHit) {
      HapticService.mediumImpact();
    } else {
      HapticService.heavyImpact();
    }
    notifyListeners();

    final evidence = PrecisionEvidence(
      clientTimestampMonoMs: DateTime.now().millisecondsSinceEpoch,
      xTouch: xNorm,
      yTouch: yNorm,
      timeToTapMs: elapsed,
      distanceError: distance,
    );

    Future.delayed(const Duration(milliseconds: 350), () {
      onComplete(evidence);
    });
  }

  void _handleTimeout() {
    _stopwatch.stop();
    _state = PrecisionUiState.timeout;
    HapticService.vibrate();
    notifyListeners();

    final evidence = PrecisionEvidence(
      clientTimestampMonoMs: DateTime.now().millisecondsSinceEpoch,
      xTouch: 0.0,
      yTouch: 0.0,
      timeToTapMs: config.durationMs + 50,
      distanceError: 1.0,
    );

    Future.delayed(const Duration(milliseconds: 350), () {
      onComplete(evidence);
    });
  }

  @override
  void dispose() {
    _prepTimer?.cancel();
    _timeoutTimer?.cancel();
    _ticker?.cancel();
    _stopwatch.stop();
    super.dispose();
  }
}
