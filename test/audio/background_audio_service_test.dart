import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rhythm_box/audio/background_audio_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel(BackgroundAudioService.channelName);
  final List<MethodCall> log = [];

  setUp(() {
    log.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      log.add(methodCall);
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('BackgroundAudioService', () {
    test('start() invokes startService when supported', () async {
      final service = BackgroundAudioService(
        channel: channel,
        isSupported: true,
      );

      await service.start();

      expect(log, hasLength(1));
      expect(log.first.method, 'startService');
      service.dispose();
    });

    test('stop() invokes stopService when supported', () async {
      final service = BackgroundAudioService(
        channel: channel,
        isSupported: true,
      );

      await service.stop();

      expect(log, hasLength(1));
      expect(log.first.method, 'stopService');
      service.dispose();
    });

    test('start() and stop() do not invoke channel when unsupported', () async {
      final service = BackgroundAudioService(
        channel: channel,
        isSupported: false,
      );

      await service.start();
      await service.stop();

      expect(log, isEmpty);
      service.dispose();
    });

    test('dispatches onNotificationStop to registered listeners', () async {
      final service = BackgroundAudioService(
        channel: channel,
        isSupported: true,
      );

      var stopCount1 = 0;
      var stopCount2 = 0;

      void listener1() => stopCount1++;
      void listener2() => stopCount2++;

      service.addStopListener(listener1);
      service.addStopListener(listener2);

      // Simulate native platform sending onNotificationStop
      await service.handleMethodCallForTesting(
        const MethodCall('onNotificationStop'),
      );

      expect(stopCount1, 1);
      expect(stopCount2, 1);

      // Remove listener1 and dispatch again
      service.removeStopListener(listener1);
      await service.handleMethodCallForTesting(
        const MethodCall('onNotificationStop'),
      );

      expect(stopCount1, 1);
      expect(stopCount2, 2);

      service.dispose();
    });

    test('handles MissingPluginException gracefully without throwing', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        throw MissingPluginException();
      });

      final service = BackgroundAudioService(
        channel: channel,
        isSupported: true,
      );

      await expectLater(service.start(), completes);
      await expectLater(service.stop(), completes);

      service.dispose();
    });

    test('dispose removes listeners and unbinds method call handler', () async {
      final service = BackgroundAudioService(
        channel: channel,
        isSupported: true,
      );

      var called = false;
      service.addStopListener(() => called = true);
      service.dispose();

      await service.handleMethodCallForTesting(
        const MethodCall('onNotificationStop'),
      );
      expect(called, isFalse);
    });
  });
}
