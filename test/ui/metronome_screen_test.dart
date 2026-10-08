import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rhythm_box/ui/metronome_screen.dart';
import '../audio/fake_audio_engine.dart';
import '../persistence/fake_settings_store.dart';
import 'package:rhythm_box/ui/playback_controller.dart';
import 'package:rhythm_box/persistence/settings_store.dart';

void main() {
  testWidgets('MetronomeScreen layout contains all required controls', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          audioEngineProvider.overrideWithValue(FakeAudioEngine()),
          settingsStoreProvider.overrideWithValue(FakeSettingsStore()),
        ],
        child: const MaterialApp(
          home: MetronomeScreen(),
        ),
      ),
    );

    // Initial build
    await tester.pumpAndSettle();

    // Verify Tempo controls
    expect(find.byKey(const Key('tempo_slider')), findsOneWidget);
    expect(find.byKey(const Key('tempo_decrement_button')), findsOneWidget);
    expect(find.byKey(const Key('tempo_increment_button')), findsOneWidget);
    expect(find.textContaining('BPM'), findsOneWidget);

    // Verify Playback controls
    expect(find.byKey(const Key('play_stop_button')), findsOneWidget);
    expect(find.text('Play'), findsOneWidget); // initially not playing

    // Verify Settings controls
    expect(find.byKey(const Key('beats_per_bar_slider')), findsOneWidget);
    expect(find.byKey(const Key('accent_toggle')), findsOneWidget);
    expect(find.byKey(const Key('waveform_segmented_button')), findsOneWidget);
    expect(find.byKey(const Key('pitch_slider')), findsOneWidget);
    expect(find.byKey(const Key('decay_slider')), findsOneWidget);
  });

  testWidgets('MetronomeScreen updates tempo and settings on interaction', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          audioEngineProvider.overrideWithValue(FakeAudioEngine()),
          settingsStoreProvider.overrideWithValue(FakeSettingsStore()),
        ],
        child: const MaterialApp(
          home: MetronomeScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Interact with tempo increment
    await tester.tap(find.byKey(const Key('tempo_increment_button')));
    await tester.pumpAndSettle();
    expect(find.text('Tempo: 121 BPM'), findsOneWidget);

    // Interact with accent toggle
    final accentToggle = find.byKey(const Key('accent_toggle'));
    await tester.tap(accentToggle);
    await tester.pumpAndSettle();
    
    // Interact with play/stop
    final playButton = find.byKey(const Key('play_stop_button'));
    await tester.tap(playButton);
    await tester.pumpAndSettle();
    expect(find.text('Stop'), findsOneWidget);
  });

  testWidgets('modifying settings during playback keeps playback running', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final fakeEngine = FakeAudioEngine();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          audioEngineProvider.overrideWithValue(fakeEngine),
          settingsStoreProvider.overrideWithValue(FakeSettingsStore()),
        ],
        child: const MaterialApp(
          home: MetronomeScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Start playback
    await tester.tap(find.byKey(const Key('play_stop_button')));
    await tester.pumpAndSettle();
    expect(find.text('Stop'), findsOneWidget);
    expect(fakeEngine.isPlaying, isTrue);

    // Toggle accent during playback
    await tester.tap(find.byKey(const Key('accent_toggle')));
    await tester.pumpAndSettle();
    expect(find.text('Stop'), findsOneWidget);
    expect(fakeEngine.isPlaying, isTrue);

    // Change waveform during playback
    await tester.tap(find.text('Square'));
    await tester.pumpAndSettle();
    expect(find.text('Stop'), findsOneWidget);
    expect(fakeEngine.isPlaying, isTrue);

    // Modify pitch slider during playback
    final pitchSlider = find.byKey(const Key('pitch_slider'));
    await tester.drag(pitchSlider, const Offset(50.0, 0.0));
    await tester.pumpAndSettle();
    expect(find.text('Stop'), findsOneWidget);
    expect(fakeEngine.isPlaying, isTrue);

    // Modify decay slider during playback
    final decaySlider = find.byKey(const Key('decay_slider'));
    await tester.drag(decaySlider, const Offset(-30.0, 0.0));
    await tester.pumpAndSettle();
    expect(find.text('Stop'), findsOneWidget);
    expect(fakeEngine.isPlaying, isTrue);

    // Verify swapLoopAtBoundary was triggered repeatedly without ever calling stop
    expect(fakeEngine.swapLoopCalls, greaterThanOrEqualTo(4));
    expect(fakeEngine.stopCalls, equals(0));
  });
}
