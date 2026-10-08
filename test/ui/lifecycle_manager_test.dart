import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rhythm_box/audio/background_audio_service.dart';
import 'package:rhythm_box/persistence/settings_store.dart';
import 'package:rhythm_box/ui/home_screen.dart';
import 'package:rhythm_box/ui/lifecycle_manager.dart';
import 'package:rhythm_box/ui/metronome_controller.dart';
import 'package:rhythm_box/ui/playback_controller.dart';

import '../audio/fake_audio_engine.dart';
import '../audio/fake_background_audio_service.dart';
import '../persistence/fake_settings_store.dart';

class FailingAudioEngine extends FakeAudioEngine {
  bool shouldFailInit = false;
  int initCalls = 0;
  int disposeCalls = 0;

  @override
  Future<void> init() async {
    initCalls++;
    if (shouldFailInit) {
      throw Exception('Hardware device not found');
    }
    await super.init();
  }

  @override
  Future<void> dispose() async {
    disposeCalls++;
    await super.dispose();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppLifecycleManager', () {
    testWidgets('calls init on engine upon startup', (tester) async {
      final fakeEngine = FailingAudioEngine();
      final fakeStore = FakeSettingsStore();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            audioEngineProvider.overrideWithValue(fakeEngine),
            settingsStoreProvider.overrideWithValue(fakeStore),
          ],
          child: const MaterialApp(
            home: AppLifecycleManager(
              child: Text('App Content'),
            ),
          ),
        ),
      );

      await tester.pump();
      expect(fakeEngine.initCalls, equals(1));
      expect(fakeEngine.isInitialized, isTrue);
      expect(find.text('App Content'), findsOneWidget);
    });

    testWidgets('bubbles initialization error to UI banner and allows retry',
        (tester) async {
      final fakeEngine = FailingAudioEngine()..shouldFailInit = true;
      final fakeStore = FakeSettingsStore();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            audioEngineProvider.overrideWithValue(fakeEngine),
            settingsStoreProvider.overrideWithValue(fakeStore),
          ],
          child: const MaterialApp(
            home: AppLifecycleManager(
              child: HomeScreen(),
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.byKey(const Key('audio_error_banner')), findsOneWidget);
      expect(find.textContaining('Hardware device not found'), findsOneWidget);

      // Now resolve error and tap Retry
      fakeEngine.shouldFailInit = false;
      await tester.tap(find.byKey(const Key('retry_audio_init_button')));
      await tester.pump();

      expect(find.byKey(const Key('audio_error_banner')), findsNothing);
      expect(fakeEngine.isInitialized, isTrue);
    });

    testWidgets('calls engine.dispose on AppLifecycleState.detached',
        (tester) async {
      final fakeEngine = FailingAudioEngine();
      final fakeStore = FakeSettingsStore();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            audioEngineProvider.overrideWithValue(fakeEngine),
            settingsStoreProvider.overrideWithValue(fakeStore),
          ],
          child: const MaterialApp(
            home: AppLifecycleManager(
              child: Text('App Content'),
            ),
          ),
        ),
      );

      await tester.pump();
      expect(fakeEngine.disposeCalls, equals(0));

      // Simulate app detached lifecycle event
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.detached);
      await tester.pump();

      expect(fakeEngine.disposeCalls, equals(1));
    });

    testWidgets('stops active playback when notification stop is received',
        (tester) async {
      final fakeEngine = FailingAudioEngine();
      final fakeStore = FakeSettingsStore();
      final fakeBackgroundService = FakeBackgroundAudioService();

      late WidgetRef capturedRef;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            audioEngineProvider.overrideWithValue(fakeEngine),
            settingsStoreProvider.overrideWithValue(fakeStore),
            backgroundAudioServiceProvider
                .overrideWithValue(fakeBackgroundService),
          ],
          child: MaterialApp(
            home: AppLifecycleManager(
              child: Consumer(
                builder: (context, ref, _) {
                  capturedRef = ref;
                  return const Text('App Content');
                },
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      // Start metronome playback
      await capturedRef.read(metronomeControllerProvider.notifier).start();
      await tester.pump();
      expect(capturedRef.read(metronomeControllerProvider).isPlaying, isTrue);

      // Trigger notification stop
      fakeBackgroundService.triggerNotificationStop();
      await tester.pump();

      expect(capturedRef.read(metronomeControllerProvider).isPlaying, isFalse);
    });
  });
}
