import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../core/services/haptic_service.dart';
import '../../../domain/challenge/challenge_config.dart';
import '../../../domain/challenge/challenge_evidence.dart';

enum MemoryUiState { preparing, playback, inputMode, failed, completed }

class MemoryRuntimeController extends ChangeNotifier {
  final MemoryConfig config;
  final void Function(MemoryEvidence evidence) onComplete;

  MemoryUiState _state = MemoryUiState.preparing;
  MemoryUiState get state => _state;

  int _activeTileIndex = -1;
  int get activeTileIndex => _activeTileIndex;

  int _failedTileIndex = -1;
  int get failedTileIndex => _failedTileIndex;

  int _userProgressIndex = 0;
  int get userProgressIndex => _userProgressIndex;

  final Stopwatch _stopwatch = Stopwatch();
  final List<Map<String, dynamic>> _rawTaps = [];
  Timer? _playbackTimer;
  Timer? _timeoutTimer;

  MemoryRuntimeController({required this.config, required this.onComplete});

  void start() {
    _state = MemoryUiState.preparing;
    notifyListeners();

    Future.delayed(const Duration(milliseconds: 800), () {
      _startPlayback();
    });
  }

  void _startPlayback() async {
    _state = MemoryUiState.playback;
    notifyListeners();

    for (var i = 0; i < config.sequence.length; i++) {
      if (_state != MemoryUiState.playback) return;

      _activeTileIndex = config.sequence[i];
      HapticService.selectionClick();
      notifyListeners();

      await Future.delayed(const Duration(milliseconds: 400));
      _activeTileIndex = -1;
      notifyListeners();

      if (i < config.sequence.length - 1) {
        await Future.delayed(const Duration(milliseconds: 150));
      }
    }

    _startInputMode();
  }

  void _startInputMode() {
    _state = MemoryUiState.inputMode;
    _userProgressIndex = 0;
    _stopwatch.reset();
    _stopwatch.start();
    HapticService.lightImpact();
    notifyListeners();

    // 6.0 second input timeout
    _timeoutTimer = Timer(const Duration(milliseconds: 6000), () {
      if (_state == MemoryUiState.inputMode) {
        _finishAttempt(isTimeout: true);
      }
    });
  }

  void handleTileTap(int tileIndex) {
    if (_state != MemoryUiState.inputMode) return;

    final elapsed = _stopwatch.elapsedMilliseconds;
    _rawTaps.add({'tile_id': tileIndex, 't': elapsed});

    final expectedTile = config.sequence[_userProgressIndex];

    if (tileIndex == expectedTile) {
      // Correct tile tap
      _userProgressIndex++;
      _activeTileIndex = tileIndex;
      HapticService.selectionClick();
      notifyListeners();

      Future.delayed(const Duration(milliseconds: 150), () {
        if (_activeTileIndex == tileIndex) {
          _activeTileIndex = -1;
          notifyListeners();
        }
      });

      if (_userProgressIndex == config.sequence.length) {
        // Full sequence completed successfully
        _finishAttempt(isSuccess: true);
      }
    } else {
      // Incorrect tile tap: immediate failure & lock
      _failedTileIndex = tileIndex;
      _state = MemoryUiState.failed;
      HapticService.heavyImpact();
      notifyListeners();

      _finishAttempt(isSuccess: false);
    }
  }

  void _finishAttempt({bool isSuccess = false, bool isTimeout = false}) {
    _timeoutTimer?.cancel();
    _stopwatch.stop();
    final completionTime = _stopwatch.elapsedMilliseconds;

    _state = isSuccess
        ? MemoryUiState.completed
        : (isTimeout ? MemoryUiState.completed : MemoryUiState.failed);
    notifyListeners();

    final evidence = MemoryEvidence(
      clientTimestampMonoMs: DateTime.now().millisecondsSinceEpoch,
      correctCount: _userProgressIndex,
      sequenceLength: config.sequenceLength,
      completionTimeMs: completionTime,
      rawTaps: _rawTaps,
    );

    Future.delayed(const Duration(milliseconds: 400), () {
      onComplete(evidence);
    });
  }

  @override
  void dispose() {
    _playbackTimer?.cancel();
    _timeoutTimer?.cancel();
    _stopwatch.stop();
    super.dispose();
  }
}
