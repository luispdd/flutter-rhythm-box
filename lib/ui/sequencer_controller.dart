import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../audio/audio_engine.dart';
import '../domain/pattern.dart';
import '../persistence/settings_store.dart';
import '../synth/pattern_renderer.dart';
import 'app_error.dart';
import 'metronome_controller.dart';
import 'playback_controller.dart';
import 'sequence_controller.dart';

/// Immutable state describing the active sequencer pattern and playback status.
@immutable
class SequencerState {
  final Pattern pattern;
  final bool isPlaying;

  const SequencerState({
    required this.pattern,
    this.isPlaying = false,
  });

  factory SequencerState.initial() => SequencerState(
        pattern: Pattern.empty(),
        isPlaying: false,
      );

  SequencerState copyWith({
    Pattern? pattern,
    bool? isPlaying,
  }) {
    return SequencerState(
      pattern: pattern ?? this.pattern,
      isPlaying: isPlaying ?? this.isPlaying,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SequencerState &&
          runtimeType == other.runtimeType &&
          pattern == other.pattern &&
          isPlaying == other.isPlaying;

  @override
  int get hashCode => Object.hash(pattern, isPlaying);
}

/// Riverpod [Notifier] managing [Pattern], playback status,
/// and persistence via [SettingsStore].
class SequencerController extends Notifier<SequencerState> {
  @override
  SequencerState build() {
    ref.listen<int>(tempoProvider, (previous, next) {
      if (previous != null && previous != next && state.isPlaying) {
        _restartPlayback(bpm: next.toDouble());
      }
    });

    _loadInitialSettings();
    return SequencerState.initial();
  }

  Future<void> _loadInitialSettings() async {
    try {
      final store = ref.read(settingsStoreProvider);
      final loaded = await store.loadWorkingPattern();
      if (loaded != null) {
        state = state.copyWith(pattern: loaded);
      }
    } catch (_) {
      // Store may not be overridden or access failed; retain initial defaults.
    }
  }

  /// Explicitly loads pattern from the active [SettingsStore] and updates [state].
  Future<void> loadFromStore() => _loadInitialSettings();

  Future<void> _updatePattern(Pattern newPattern) async {
    state = state.copyWith(pattern: newPattern);
    try {
      final store = ref.read(settingsStoreProvider);
      await store.saveWorkingPattern(newPattern);
    } catch (e) {
      if (!isStoreUnimplemented(e)) {
        ref.read(appErrorProvider.notifier).setError('Failed to save working pattern: $e');
        showAppSnackBar('Failed to save working pattern');
      }
    }
    if (state.isPlaying) {
      await _restartPlayback(pattern: newPattern);
    }
  }

  AudioEngine get _engine => ref.read(audioEngineProvider);
  PatternRenderer get _renderer => ref.read(patternRendererProvider);

  /// Starts sequencer looped playback.
  Future<void> start() async {
    if (state.isPlaying) return;

    ref.read(metronomeControllerProvider.notifier).onExternalStop();
    ref.read(sequenceControllerProvider.notifier).onExternalStop();

    final bpm = ref.read(tempoProvider).toDouble();
    final buffer = _renderer.renderBuffer(state.pattern, bpm: bpm);

    try {
      if (_engine.isPlaying) {
        await _engine.swapLoopAtBoundary(buffer);
      } else {
        await _engine.startLoop(buffer);
      }
      state = state.copyWith(isPlaying: true);
      ref.read(audioErrorProvider.notifier).clear();
    } catch (e) {
      state = state.copyWith(isPlaying: false);
      final msg = 'Audio playback failed: $e';
      ref.read(audioErrorProvider.notifier).setError(msg);
      showAppSnackBar(msg);
    }
  }

  /// Ceases sequencer playback immediately.
  Future<void> stop() async {
    if (!state.isPlaying) return;

    await _engine.stop();
    state = state.copyWith(isPlaying: false);
  }

  /// Toggles playback between playing and stopped.
  Future<void> togglePlay() async {
    if (state.isPlaying) {
      await stop();
    } else {
      await start();
    }
  }

  Future<void> _restartPlayback({double? bpm, Pattern? pattern}) async {
    if (!state.isPlaying) return;

    final effectiveBpm = bpm ?? ref.read(tempoProvider).toDouble();
    final effectivePattern = pattern ?? state.pattern;
    final buffer = _renderer.renderBuffer(effectivePattern, bpm: effectiveBpm);

    await _engine.swapLoopAtBoundary(buffer);
  }

  /// Toggles the step at [trackIndex] and [stepIndex].
  Future<void> toggleStep(int trackIndex, int stepIndex) async {
    final updated = state.pattern.toggleStep(trackIndex, stepIndex);
    await _updatePattern(updated);
  }

  /// Updates the active step count.
  Future<void> setStepCount(int count) async {
    final updated = state.pattern.setStepCount(count);
    await _updatePattern(updated);
  }

  /// Clears the pattern.
  Future<void> clearPattern() async {
    final updated = state.pattern.clear();
    await _updatePattern(updated);
  }

  /// Loads a complete pattern into the sequencer.
  Future<void> loadPattern(Pattern pattern) async {
    await _updatePattern(pattern);
  }

  /// Invoked when external playback (such as the metronome) starts.
  void onExternalStop() {
    if (state.isPlaying) {
      state = state.copyWith(isPlaying: false);
    }
  }
}

/// Global provider for [SequencerController].
final sequencerControllerProvider =
    NotifierProvider<SequencerController, SequencerState>(
        SequencerController.new);
