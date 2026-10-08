import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../audio/audio_engine.dart';
import '../audio/background_audio_service.dart';
import '../audio/soloud_audio_engine.dart';
import '../domain/metronome_settings.dart';
import '../domain/pattern.dart';
import '../synth/metronome_renderer.dart';
import '../synth/pattern_renderer.dart';
import 'tempo_controller.dart';

export 'tempo_controller.dart';

/// Provider exposing the active [AudioEngine] instance.
/// Overridable in widget or unit tests with a mock/fake engine.
final audioEngineProvider = Provider<AudioEngine>((ref) {
  final engine = SoLoudAudioEngine();
  ref.onDispose(() {
    engine.dispose();
  });
  return engine;
});

/// Provider exposing the metronome audio renderer.
final metronomeRendererProvider = Provider<MetronomeRenderer>((ref) {
  return const MetronomeRenderer();
});

/// Provider exposing the sequencer pattern audio renderer.
final patternRendererProvider = Provider<PatternRenderer>((ref) {
  return const PatternRenderer();
});

/// Helper to create predefined spike patterns for the UI and testing.
Pattern _createSpikePattern({
  required String id,
  required String name,
  required List<bool> track0Steps,
  int stepCount = 4,
}) {
  final tracks = List.generate(
    Pattern.trackCount,
    (_) => List.filled(Pattern.stepsPerTrack, false),
  );
  for (var s = 0; s < track0Steps.length && s < Pattern.stepsPerTrack; s++) {
    tracks[0][s] = track0Steps[s];
  }
  return Pattern(
    id: id,
    name: name,
    stepCount: stepCount,
    tracks: tracks,
  );
}

/// Predefined pattern presets for the spike sequencer.
final List<Pattern> spikePatternPresets = [
  _createSpikePattern(
    id: 'four_on_floor',
    name: 'All 4 Steps (16ths)',
    track0Steps: [true, true, true, true],
    stepCount: 4,
  ),
  _createSpikePattern(
    id: 'alternating',
    name: 'Alternating (8ths)',
    track0Steps: [true, false, true, false],
    stepCount: 4,
  ),
  _createSpikePattern(
    id: 'syncopated',
    name: 'Syncopated [X X . X]',
    track0Steps: [true, true, false, true],
    stepCount: 4,
  ),
  _createSpikePattern(
    id: 'off_beat',
    name: 'Off-Beat [. X . X]',
    track0Steps: [false, true, false, true],
    stepCount: 4,
  ),
];

/// Riverpod [Notifier] managing adjustable [MetronomeSettings].
class MetronomeSettingsNotifier extends Notifier<MetronomeSettings> {
  @override
  MetronomeSettings build() => MetronomeSettings();

  void update(MetronomeSettings settings) => state = settings;

  void setBeatsPerBar(int beats) =>
      state = state.copyWith(beatsPerBar: beats);

  void toggleAccent() => state = state.copyWith(accent: !state.accent);

  void setPitchHz(double pitchHz) =>
      state = state.copyWith(pitchHz: pitchHz);

  void setDecayMs(double decayMs) =>
      state = state.copyWith(decayMs: decayMs);
}

/// Provider exposing current [MetronomeSettings].
final metronomeSettingsProvider =
    NotifierProvider<MetronomeSettingsNotifier, MetronomeSettings>(
        MetronomeSettingsNotifier.new);

/// Riverpod [Notifier] managing the active sequencer [Pattern].
class SequencerPatternNotifier extends Notifier<Pattern> {
  @override
  Pattern build() => spikePatternPresets.first;

  void setPattern(Pattern pattern) => state = pattern;

  void toggleStep(int trackIndex, int stepIndex) =>
      state = state.toggleStep(trackIndex, stepIndex);

  void setStepCount(int stepCount) =>
      state = state.setStepCount(stepCount);

  void clear() => state = state.clear();
}

/// Provider exposing the active sequencer [Pattern].
final sequencerPatternProvider =
    NotifierProvider<SequencerPatternNotifier, Pattern>(
        SequencerPatternNotifier.new);

/// State describing the metronome playback controller.
@immutable
class MetronomePlaybackState {
  final bool isPlaying;
  final String lastEvent;

  const MetronomePlaybackState({
    this.isPlaying = false,
    this.lastEvent = 'Ready',
  });

  MetronomePlaybackState copyWith({
    bool? isPlaying,
    String? lastEvent,
  }) {
    return MetronomePlaybackState(
      isPlaying: isPlaying ?? this.isPlaying,
      lastEvent: lastEvent ?? this.lastEvent,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MetronomePlaybackState &&
          runtimeType == other.runtimeType &&
          isPlaying == other.isPlaying &&
          lastEvent == other.lastEvent;

  @override
  int get hashCode => Object.hash(isPlaying, lastEvent);
}

/// State describing the sequencer playback controller.
@immutable
class SequencerPlaybackState {
  final bool isPlaying;
  final String lastEvent;

  const SequencerPlaybackState({
    this.isPlaying = false,
    this.lastEvent = 'Ready',
  });

  SequencerPlaybackState copyWith({
    bool? isPlaying,
    String? lastEvent,
  }) {
    return SequencerPlaybackState(
      isPlaying: isPlaying ?? this.isPlaying,
      lastEvent: lastEvent ?? this.lastEvent,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SequencerPlaybackState &&
          runtimeType == other.runtimeType &&
          isPlaying == other.isPlaying &&
          lastEvent == other.lastEvent;

  @override
  int get hashCode => Object.hash(isPlaying, lastEvent);
}

/// Controller managing metronome playback through the [AudioEngine].
class MetronomePlaybackController extends Notifier<MetronomePlaybackState> {
  @override
  MetronomePlaybackState build() {
    ref.listen<int>(tempoProvider, (previous, next) {
      if (previous != null && previous != next && state.isPlaying) {
        _swapAtBoundary(bpm: next.toDouble());
      }
    });

    ref.listen<MetronomeSettings>(metronomeSettingsProvider, (previous, next) {
      if (previous != null && previous != next && state.isPlaying) {
        _swapAtBoundary(settings: next);
      }
    });

    return const MetronomePlaybackState();
  }

  AudioEngine get _engine => ref.read(audioEngineProvider);
  BackgroundAudioService get _backgroundService =>
      ref.read(backgroundAudioServiceProvider);
  MetronomeRenderer get _renderer => ref.read(metronomeRendererProvider);

  /// Starts metronome playback or swaps to it if playback is already active.
  Future<void> start() async {
    final tempo = ref.read(tempoProvider).toDouble();
    final settings = ref.read(metronomeSettingsProvider);
    final buffer = _renderer.renderBuffer(settings: settings, bpm: tempo);

    // If sequencer was active, mark it inactive
    ref.read(sequencerPlaybackControllerProvider.notifier).onExternalStop();

    if (_engine.isPlaying) {
      await _engine.swapLoopAtBoundary(buffer);
    } else {
      await _engine.startLoop(buffer);
    }

    state = state.copyWith(
      isPlaying: true,
      lastEvent: 'Metronome running at ${tempo.round()} BPM',
    );
    unawaited(_backgroundService.start());
  }

  /// Stops metronome playback immediately.
  Future<void> stop() async {
    if (state.isPlaying) {
      await _engine.stop();
      state = state.copyWith(
        isPlaying: false,
        lastEvent: 'Metronome stopped',
      );
      unawaited(_backgroundService.stop());
    }
  }

  Future<void> _swapAtBoundary({double? bpm, MetronomeSettings? settings}) async {
    final effectiveBpm = bpm ?? ref.read(tempoProvider).toDouble();
    final MetronomeSettings effectiveSettings =
        settings ?? ref.read(metronomeSettingsProvider);
    final buffer = _renderer.renderBuffer(
      settings: effectiveSettings,
      bpm: effectiveBpm,
    );

    await _engine.swapLoopAtBoundary(buffer);
    state = state.copyWith(
      lastEvent: 'Metronome swapped at boundary (${effectiveBpm.round()} BPM)',
    );
  }

  /// Invoked when another playback source starts or global stop is triggered.
  void onExternalStop() {
    if (state.isPlaying) {
      state = state.copyWith(
        isPlaying: false,
        lastEvent: 'Stopped by external source',
      );
    }
  }
}

/// Provider exposing [MetronomePlaybackController].
final metronomePlaybackControllerProvider =
    NotifierProvider<MetronomePlaybackController, MetronomePlaybackState>(
        MetronomePlaybackController.new);

/// Controller managing sequencer pattern playback through the [AudioEngine].
class SequencerPlaybackController extends Notifier<SequencerPlaybackState> {
  @override
  SequencerPlaybackState build() {
    ref.listen<int>(tempoProvider, (previous, next) {
      if (previous != null && previous != next && state.isPlaying) {
        _swapAtBoundary(bpm: next.toDouble());
      }
    });

    ref.listen<Pattern>(sequencerPatternProvider, (previous, next) {
      if (previous != null && previous != next && state.isPlaying) {
        _swapAtBoundary(pattern: next);
      }
    });

    return const SequencerPlaybackState();
  }

  AudioEngine get _engine => ref.read(audioEngineProvider);
  BackgroundAudioService get _backgroundService =>
      ref.read(backgroundAudioServiceProvider);
  PatternRenderer get _renderer => ref.read(patternRendererProvider);

  /// Starts sequencer pattern playback or swaps to it if playback is already active.
  Future<void> start() async {
    final tempo = ref.read(tempoProvider).toDouble();
    final pattern = ref.read(sequencerPatternProvider);
    final buffer = _renderer.renderBuffer(pattern, bpm: tempo);

    // If metronome was active, mark it inactive
    ref.read(metronomePlaybackControllerProvider.notifier).onExternalStop();

    if (_engine.isPlaying) {
      await _engine.swapLoopAtBoundary(buffer);
    } else {
      await _engine.startLoop(buffer);
    }

    state = state.copyWith(
      isPlaying: true,
      lastEvent: 'Sequencer running at ${tempo.round()} BPM',
    );
    unawaited(_backgroundService.start());
  }

  /// Stops sequencer playback immediately.
  Future<void> stop() async {
    if (state.isPlaying) {
      await _engine.stop();
      state = state.copyWith(
        isPlaying: false,
        lastEvent: 'Sequencer stopped',
      );
      unawaited(_backgroundService.stop());
    }
  }

  Future<void> _swapAtBoundary({double? bpm, Pattern? pattern}) async {
    final effectiveBpm = bpm ?? ref.read(tempoProvider).toDouble();
    final Pattern effectivePattern =
        pattern ?? ref.read(sequencerPatternProvider);
    final buffer = _renderer.renderBuffer(effectivePattern, bpm: effectiveBpm);

    await _engine.swapLoopAtBoundary(buffer);
    state = state.copyWith(
      lastEvent: 'Sequencer swapped at boundary (${effectiveBpm.round()} BPM)',
    );
  }

  /// Invoked when another playback source starts or global stop is triggered.
  void onExternalStop() {
    if (state.isPlaying) {
      state = state.copyWith(
        isPlaying: false,
        lastEvent: 'Stopped by external source',
      );
    }
  }
}

/// Provider exposing [SequencerPlaybackController].
final sequencerPlaybackControllerProvider =
    NotifierProvider<SequencerPlaybackController, SequencerPlaybackState>(
        SequencerPlaybackController.new);

/// Stops all active audio engine playback and resets playback controller states.
Future<void> stopAllPlayback(WidgetRef ref) async {
  await ref.read(audioEngineProvider).stop();
  unawaited(ref.read(backgroundAudioServiceProvider).stop());
  ref.read(metronomePlaybackControllerProvider.notifier).onExternalStop();
  ref.read(sequencerPlaybackControllerProvider.notifier).onExternalStop();
}
