import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rhythm_box/ui/playback_controller.dart';
import 'audio/fake_audio_engine.dart';

void main() {
  group('Metronome & Sequencer Playback Controllers', () {
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

    group('MetronomePlaybackController', () {
      test('initial state is idle', () {
        final state = container.read(metronomePlaybackControllerProvider);
        expect(state.isPlaying, isFalse);
      });

      test('start begins playback on fake audio engine', () async {
        final controller =
            container.read(metronomePlaybackControllerProvider.notifier);
        await controller.start();

        final state = container.read(metronomePlaybackControllerProvider);
        expect(state.isPlaying, isTrue);
        expect(fakeEngine.startLoopCalls, equals(1));
        expect(fakeEngine.lastStartedBuffer, isNotNull);
        expect(fakeEngine.lastStartedBuffer!.totalSamples, greaterThan(0));
      });

      test('stop stops playback on audio engine', () async {
        final controller =
            container.read(metronomePlaybackControllerProvider.notifier);
        await controller.start();
        expect(
            container.read(metronomePlaybackControllerProvider).isPlaying,
            isTrue);

        await controller.stop();
        final state = container.read(metronomePlaybackControllerProvider);
        expect(state.isPlaying, isFalse);
        expect(fakeEngine.stopCalls, equals(1));
      });

      test('changing tempo while playing triggers a swap and NOT a restart',
          () async {
        final controller =
            container.read(metronomePlaybackControllerProvider.notifier);
        await controller.start();

        expect(fakeEngine.startLoopCalls, equals(1));
        expect(fakeEngine.swapLoopCalls, equals(0));

        // Change global tempo
        container.read(tempoProvider.notifier).setBpm(140);

        // Verify that a boundary swap was called, not a restart
        expect(fakeEngine.startLoopCalls, equals(1));
        expect(fakeEngine.swapLoopCalls, equals(1));
        expect(fakeEngine.lastSwappedBuffer, isNotNull);
        expect(fakeEngine.lastSwappedBuffer!.totalSamples, greaterThan(0));
      });

      test('changing settings while playing triggers a swap', () async {
        final controller =
            container.read(metronomePlaybackControllerProvider.notifier);
        await controller.start();
        expect(fakeEngine.swapLoopCalls, equals(0));

        container.read(metronomeSettingsProvider.notifier).setBeatsPerBar(3);

        expect(fakeEngine.startLoopCalls, equals(1));
        expect(fakeEngine.swapLoopCalls, equals(1));
      });

      test('changing tempo while stopped does not call engine swap', () async {
        container.read(tempoProvider.notifier).setBpm(90);

        expect(fakeEngine.startLoopCalls, equals(0));
        expect(fakeEngine.swapLoopCalls, equals(0));

        // Starting now renders at the updated tempo
        await container
            .read(metronomePlaybackControllerProvider.notifier)
            .start();
        expect(fakeEngine.startLoopCalls, equals(1));
      });
    });

    group('SequencerPlaybackController', () {
      test('initial state is idle', () {
        final state = container.read(sequencerPlaybackControllerProvider);
        expect(state.isPlaying, isFalse);
      });

      test('start begins playback on fake audio engine', () async {
        final controller =
            container.read(sequencerPlaybackControllerProvider.notifier);
        await controller.start();

        final state = container.read(sequencerPlaybackControllerProvider);
        expect(state.isPlaying, isTrue);
        expect(fakeEngine.startLoopCalls, equals(1));
        expect(fakeEngine.lastStartedBuffer, isNotNull);
        expect(fakeEngine.lastStartedBuffer!.totalSamples, greaterThan(0));
      });

      test('stop stops playback on audio engine', () async {
        final controller =
            container.read(sequencerPlaybackControllerProvider.notifier);
        await controller.start();
        expect(
            container.read(sequencerPlaybackControllerProvider).isPlaying,
            isTrue);

        await controller.stop();
        final state = container.read(sequencerPlaybackControllerProvider);
        expect(state.isPlaying, isFalse);
        expect(fakeEngine.stopCalls, equals(1));
      });

      test('changing tempo while playing triggers a swap and NOT a restart',
          () async {
        final controller =
            container.read(sequencerPlaybackControllerProvider.notifier);
        await controller.start();

        expect(fakeEngine.startLoopCalls, equals(1));
        expect(fakeEngine.swapLoopCalls, equals(0));

        // Change global tempo
        container.read(tempoProvider.notifier).setBpm(140);

        // Verify that a boundary swap was called, not a restart
        expect(fakeEngine.startLoopCalls, equals(1));
        expect(fakeEngine.swapLoopCalls, equals(1));
        expect(fakeEngine.lastSwappedBuffer, isNotNull);
        expect(fakeEngine.lastSwappedBuffer!.totalSamples, greaterThan(0));
      });

      test('changing pattern while playing triggers a swap', () async {
        final controller =
            container.read(sequencerPlaybackControllerProvider.notifier);
        await controller.start();
        expect(fakeEngine.swapLoopCalls, equals(0));

        container
            .read(sequencerPatternProvider.notifier)
            .setPattern(spikePatternPresets[1]);

        expect(fakeEngine.startLoopCalls, equals(1));
        expect(fakeEngine.swapLoopCalls, equals(1));
      });
    });

    group('Coordination between Metronome and Sequencer', () {
      test('switching between sequencer and metronome swaps boundary cleanly',
          () async {
        final sequencer =
            container.read(sequencerPlaybackControllerProvider.notifier);
        final metronome =
            container.read(metronomePlaybackControllerProvider.notifier);

        await sequencer.start();
        expect(fakeEngine.startLoopCalls, equals(1));
        expect(
            container.read(sequencerPlaybackControllerProvider).isPlaying,
            isTrue);
        expect(
            container.read(metronomePlaybackControllerProvider).isPlaying,
            isFalse);

        // Start metronome while sequencer is active -> swaps loop at boundary
        await metronome.start();
        expect(fakeEngine.swapLoopCalls, equals(1));
        expect(
            container.read(sequencerPlaybackControllerProvider).isPlaying,
            isFalse);
        expect(
            container.read(metronomePlaybackControllerProvider).isPlaying,
            isTrue);

        // Stop metronome
        await metronome.stop();
        expect(fakeEngine.stopCalls, equals(1));
        expect(
            container.read(metronomePlaybackControllerProvider).isPlaying,
            isFalse);
      });

      test('switching between metronome and sequencer swaps boundary cleanly',
          () async {
        final sequencer =
            container.read(sequencerPlaybackControllerProvider.notifier);
        final metronome =
            container.read(metronomePlaybackControllerProvider.notifier);

        await metronome.start();
        expect(fakeEngine.startLoopCalls, equals(1));

        await sequencer.start();
        expect(fakeEngine.swapLoopCalls, equals(1));
        expect(
            container.read(metronomePlaybackControllerProvider).isPlaying,
            isFalse);
        expect(
            container.read(sequencerPlaybackControllerProvider).isPlaying,
            isTrue);
      });
    });
  });
}
