import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../audio/audio_engine.dart';
import '../audio/soloud_audio_engine.dart';
import '../domain/playback_state.dart';
import '../synth/click_synthesizer.dart';

/// Provider exposing the active [AudioEngine] instance.
/// Overridable in widget or unit tests with a mock/fake engine.
final audioEngineProvider = Provider<AudioEngine>((ref) {
  final engine = SoLoudAudioEngine();
  ref.onDispose(() {
    engine.dispose();
  });
  return engine;
});

/// Provider exposing the synthesizer renderer.
final clickSynthesizerProvider = Provider<ClickSynthesizer>((ref) {
  return const ClickSynthesizer();
});

/// State notifier managing playback state and audio engine loop swapping.
///
/// Follows Design D4: Riverpod Notifier architecture.
/// Core timing rule: Rhythm timing is 100% audio-driven.
/// No Dart `Timer` or `Future.delayed` triggers any sound onset.
class PlaybackNotifier extends Notifier<PlaybackState> {
  @override
  PlaybackState build() {
    return const PlaybackState();
  }

  AudioEngine get _engine => ref.read(audioEngineProvider);
  ClickSynthesizer get _synth => ref.read(clickSynthesizerProvider);

  /// Starts the sequencer loop (or swaps to it if already playing).
  Future<void> startSequencer() async {
    final buffer = _synth.renderPatternBuffer(
      bpm: state.bpm,
      stepCount: state.patternPreset.steps.length,
      activeSteps: state.patternPreset.steps,
    );

    if (state.isPlaying) {
      await _engine.swapLoopAtBoundary(buffer);
    } else {
      await _engine.startLoop(buffer);
    }

    state = state.copyWith(
      mode: PlaybackMode.sequencer,
      lastEvent: 'Sequencer running at ${state.bpm.round()} BPM',
    );
  }

  /// Stops sequencer playback immediately.
  Future<void> stopSequencer() async {
    if (state.mode == PlaybackMode.sequencer) {
      await _engine.stop();
      state = state.copyWith(
        mode: PlaybackMode.idle,
        lastEvent: 'Sequencer stopped',
      );
    }
  }

  /// Starts the metronome loop (or swaps to it if already playing).
  Future<void> startMetronome() async {
    final buffer = _synth.renderMetronomeBuffer(
      bpm: state.bpm,
      beatsPerBar: state.beatsPerBar,
    );

    if (state.isPlaying) {
      await _engine.swapLoopAtBoundary(buffer);
    } else {
      await _engine.startLoop(buffer);
    }

    state = state.copyWith(
      mode: PlaybackMode.metronome,
      lastEvent: 'Metronome running at ${state.bpm.round()} BPM',
    );
  }

  /// Stops metronome playback immediately.
  Future<void> stopMetronome() async {
    if (state.mode == PlaybackMode.metronome) {
      await _engine.stop();
      state = state.copyWith(
        mode: PlaybackMode.idle,
        lastEvent: 'Metronome stopped',
      );
    }
  }

  /// Stops any active playback immediately without waiting for loop boundary.
  Future<void> stop() async {
    await _engine.stop();
    state = state.copyWith(
      mode: PlaybackMode.idle,
      lastEvent: 'Playback stopped',
    );
  }

  /// Swaps tempo at the next loop boundary if playing.
  Future<void> swapTempo(double newBpm) async {
    if (newBpm == state.bpm) return;

    if (state.mode == PlaybackMode.sequencer) {
      final buffer = _synth.renderPatternBuffer(
        bpm: newBpm,
        stepCount: state.patternPreset.steps.length,
        activeSteps: state.patternPreset.steps,
      );
      await _engine.swapLoopAtBoundary(buffer);
    } else if (state.mode == PlaybackMode.metronome) {
      final buffer = _synth.renderMetronomeBuffer(
        bpm: newBpm,
        beatsPerBar: state.beatsPerBar,
      );
      await _engine.swapLoopAtBoundary(buffer);
    }

    state = state.copyWith(
      bpm: newBpm,
      lastEvent: 'Tempo swapped: ${newBpm.round()} BPM',
    );
  }

  /// Toggles tempo between 120 and 140 BPM (convenience button).
  Future<void> toggleTempo() async {
    final nextBpm = (state.bpm == 120.0) ? 140.0 : 120.0;
    await swapTempo(nextBpm);
  }

  /// Swaps pattern preset at the next loop boundary if playing sequencer.
  Future<void> swapPattern(PatternPreset newPreset) async {
    if (newPreset == state.patternPreset) return;

    if (state.mode == PlaybackMode.sequencer) {
      final buffer = _synth.renderPatternBuffer(
        bpm: state.bpm,
        stepCount: newPreset.steps.length,
        activeSteps: newPreset.steps,
      );
      await _engine.swapLoopAtBoundary(buffer);
    }

    state = state.copyWith(
      patternPreset: newPreset,
      lastEvent: 'Pattern swapped: ${newPreset.label}',
    );
  }

  /// Cycles to the next pattern preset.
  Future<void> togglePattern() async {
    final nextIndex = (state.patternPreset.index + 1) % PatternPreset.values.length;
    await swapPattern(PatternPreset.values[nextIndex]);
  }
}

/// Provider for [PlaybackState] managed by [PlaybackNotifier].
final playbackNotifierProvider =
    NotifierProvider<PlaybackNotifier, PlaybackState>(PlaybackNotifier.new);
