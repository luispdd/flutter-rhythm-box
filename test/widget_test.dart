import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rhythm_box/audio/audio_engine.dart';
import 'package:rhythm_box/domain/audio_buffer.dart';
import 'package:rhythm_box/main.dart';
import 'package:rhythm_box/ui/playback_controller.dart';

class FakeAudioEngine implements AudioEngine {
  bool _isPlaying = false;
  int startLoopCalls = 0;
  int swapLoopCalls = 0;
  int stopCalls = 0;

  @override
  bool get isPlaying => _isPlaying;

  @override
  Stream<Duration>? get positionStream => null;

  @override
  Future<void> init() async {}

  @override
  Future<void> dispose() async {}

  @override
  Future<void> startLoop(AudioBuffer buffer) async {
    _isPlaying = true;
    startLoopCalls++;
  }

  @override
  Future<void> swapLoopAtBoundary(AudioBuffer nextBuffer) async {
    swapLoopCalls++;
  }

  @override
  Future<void> stop() async {
    _isPlaying = false;
    stopCalls++;
  }
}

void main() {
  testWidgets('SpikeScreen renders controls and responds to user actions',
      (WidgetTester tester) async {
    final fakeEngine = FakeAudioEngine();

    // Set a large enough surface size so all controls are easily visible
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          audioEngineProvider.overrideWithValue(fakeEngine),
        ],
        child: const RhythmBoxApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify initial idle state
    expect(find.text('Rhythm Box - Timing Spike'), findsOneWidget);
    expect(find.text('IDLE'), findsOneWidget);
    expect(find.text('120 BPM'), findsAtLeastNWidgets(1));

    // Verify presence of buttons
    expect(find.byKey(const Key('start_sequencer_button')), findsOneWidget);
    expect(find.byKey(const Key('stop_sequencer_button')), findsOneWidget);
    expect(find.byKey(const Key('start_metronome_button')), findsOneWidget);
    expect(find.byKey(const Key('stop_metronome_button')), findsOneWidget);
    expect(find.byKey(const Key('swap_tempo_button')), findsOneWidget);
    expect(find.byKey(const Key('swap_pattern_button')), findsOneWidget);

    // Tap Start Sequencer
    await tester.tap(find.byKey(const Key('start_sequencer_button')));
    await tester.pumpAndSettle();

    expect(fakeEngine.startLoopCalls, equals(1));
    expect(find.text('SEQUENCER ACTIVE'), findsOneWidget);

    // Tap Swap Tempo button
    await tester.tap(find.byKey(const Key('swap_tempo_button')));
    await tester.pumpAndSettle();

    expect(fakeEngine.swapLoopCalls, equals(1));
    expect(find.text('140 BPM'), findsAtLeastNWidgets(1));

    // Tap Swap Pattern button
    await tester.tap(find.byKey(const Key('swap_pattern_button')));
    await tester.pumpAndSettle();

    expect(fakeEngine.swapLoopCalls, equals(2));

    // Tap Start Metronome (swaps mode while playing)
    await tester.tap(find.byKey(const Key('start_metronome_button')));
    await tester.pumpAndSettle();

    expect(fakeEngine.swapLoopCalls, equals(3));
    expect(find.text('METRONOME ACTIVE'), findsOneWidget);

    // Tap Stop Metronome
    await tester.tap(find.byKey(const Key('stop_metronome_button')));
    await tester.pumpAndSettle();

    expect(fakeEngine.stopCalls, equals(1));
    expect(find.text('IDLE'), findsOneWidget);
  });
}
