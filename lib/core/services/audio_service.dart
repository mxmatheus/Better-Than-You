abstract interface class AudioService {
  void playCountdownTick();
  void playTriggerGo();
  void playTap();
  void playSuccess();
  void playFault();
  void playReveal();
  void playVictory();
  void playDefeat();
}

final class NoOpAudioService implements AudioService {
  const NoOpAudioService();

  @override
  void playCountdownTick() {}

  @override
  void playTriggerGo() {}

  @override
  void playTap() {}

  @override
  void playSuccess() {}

  @override
  void playFault() {}

  @override
  void playReveal() {}

  @override
  void playVictory() {}

  @override
  void playDefeat() {}
}
