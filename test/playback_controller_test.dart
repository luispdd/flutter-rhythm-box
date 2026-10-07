import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rhythm_box/domain/playback_state.dart';
import 'package:rhythm_box/ui/playback_controller.dart';
import 'audio/fake_audio_engine.dart';

void main() {
  group('PlaybackNotifier', () {
    late FakeAudioEngine fakeEngine;
    late ProviderContainer container;

    setUp(() {
      fakeEngine = FakeAudioEngine();
      container = ProviderContainer(
        overrides: [
          audioEngineProvider.overrideWithValue(fakeEngine),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state is idle at 120 BPM', () {
      final state = container.read(playbackNotifierProvider);
      expect(state.mode, equals(PlaybackMode.idle));
      expect(state.bpm, equals(120.0));
      expect(state.isPlaying, isFalse);
      expect(state.patternPreset, equals(PatternPreset.fourOnTheFloor));
    });

    test('startSequencer starts engine loop with pattern buffer', () async {
      final notifier = container.read(playbackNotifierProvider.notifier);
      await notifier.startSequencer();

      final state = container.read(playbackNotifierProvider);
      expect(state.mode, equals(PlaybackMode.sequencer));
      expect(state.isPlaying, isTrue);
      expect(fakeEngine.startLoopCalls, equals(1));
      expect(fakeEngine.lastStartedBuffer, isNotNull);
      expect(fakeEngine.lastStartedBuffer!.totalSamples, greaterThan(0));
    });

    test('stopSequencer stops playback when sequencer is active', () async {
      final notifier = container.read(playbackNotifierProvider.notifier);
      await notifier.startSequencer();
      expect(container.read(playbackNotifierProvider).isPlaying, isTrue);

      await notifier.stopSequencer();
      final state = container.read(playbackNotifierProvider);
      expect(state.mode, equals(PlaybackMode.idle));
      expect(state.isPlaying, isFalse);
      expect(fakeEngine.stopCalls, equals(1));
    });

    test('startMetronome starts engine loop with metronome buffer', () async {
      final notifier = container.read(playbackNotifierProvider.notifier);
      await notifier.startMetronome();

      final state = container.read(playbackNotifierProvider);
      expect(state.mode, equals(PlaybackMode.metronome));
      expect(state.isPlaying, isTrue);
      expect(fakeEngine.startLoopCalls, equals(1));
      expect(fakeEngine.lastStartedBuffer, isNotNull);
      expect(fakeEngine.lastStartedBuffer!.totalSamples, greaterThan(0));
    });

    test('swapTempo while playing calls swapLoopAtBoundary on engine', () async {
      final notifier = container.read(playbackNotifierProvider.notifier);
      await notifier.startSequencer();
      expect(fakeEngine.startLoopCalls, equals(1));

      await notifier.swapTempo(140.0);
      final state = container.read(playbackNotifierProvider);
      expect(state.bpm, equals(140.0));
      expect(fakeEngine.swapLoopCalls, equals(1));
      expect(fakeEngine.lastSwappedBuffer, isNotNull);
      expect(fakeEngine.lastSwappedBuffer!.totalSamples, greaterThan(0));
    });

    test('toggleTempo switches between 120 and 140 BPM', () async {
      final notifier = container.read(playbackNotifierProvider.notifier);
      await notifier.startSequencer();

      await notifier.toggleTempo();
      expect(container.read(playbackNotifierProvider).bpm, equals(140.0));

      await notifier.toggleTempo();
      expect(container.read(playbackNotifierProvider).bpm, equals(120.0));
    });

    test('swapPattern while playing sequencer calls swapLoopAtBoundary', () async {
      final notifier = container.read(playbackNotifierProvider.notifier);
      await notifier.startSequencer();

      await notifier.swapPattern(PatternPreset.alternating);
      final state = container.read(playbackNotifierProvider);
      expect(state.patternPreset, equals(PatternPreset.alternating));
      expect(fakeEngine.swapLoopCalls, equals(1));
    });

    test('switching between sequencer and metronome swaps boundary cleanly', () async {
      final notifier = container.read(playbackNotifierProvider.notifier);
      await notifier.startSequencer();
      expect(fakeEngine.startLoopCalls, equals(1));

      await notifier.startMetronome();
      expect(fakeEngine.swapLoopCalls, equals(1));
      expect(container.read(playbackNotifierProvider).mode, equals(PlaybackMode.metronome));
    });
  });
}
