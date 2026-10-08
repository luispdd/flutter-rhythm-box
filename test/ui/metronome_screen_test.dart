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
}
