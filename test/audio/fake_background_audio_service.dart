import 'package:flutter/services.dart';
import 'package:rhythm_box/audio/background_audio_service.dart';

/// Test double for [BackgroundAudioService].
class FakeBackgroundAudioService extends BackgroundAudioService {
  int startCalls = 0;
  int stopCalls = 0;

  FakeBackgroundAudioService() : super(isSupported: false);

  @override
  Future<void> start() async {
    startCalls++;
  }

  @override
  Future<void> stop() async {
    stopCalls++;
  }

  void triggerNotificationStop() {
    handleMethodCallForTesting(const MethodCall('onNotificationStop'));
  }
}
