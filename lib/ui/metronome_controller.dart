import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../audio/audio_engine.dart';
import '../domain/metronome_settings.dart';
import '../domain/voice.dart';
import '../persistence/settings_store.dart';
import '../synth/metronome_renderer.dart';
import 'playback_controller.dart';
import 'sequencer_controller.dart';

/// Immutable state describing the active metronome configuration and playback status.
@immutable
class MetronomeState {
  final MetronomeSettings settings;
  final bool isPlaying;

  const MetronomeState({
    required this.settings,
    this.isPlaying = false,
  });

  factory MetronomeState.initial() => MetronomeState(
        settings: MetronomeSettings(),
        isPlaying: false,
      );

  MetronomeState copyWith({
    MetronomeSettings? settings,
    bool? isPlaying,
  }) {
    return MetronomeState(
      settings: settings ?? this.settings,
      isPlaying: isPlaying ?? this.isPlaying,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MetronomeState &&
          runtimeType == other.runtimeType &&
          settings == other.settings &&
          isPlaying == other.isPlaying;

  @override
  int get hashCode => Object.hash(settings, isPlaying);
}

/// Riverpod [Notifier] managing [MetronomeSettings], playback status,
/// persistence via [SettingsStore], and audio looping/swapping via [AudioEngine].
class MetronomeController extends Notifier<MetronomeState> {
  @override
  MetronomeState build() {
    // Listen for global tempo changes to trigger seamless boundary swaps when playing.
    ref.listen<int>(tempoProvider, (previous, next) {
      if (previous != null && previous != next && state.isPlaying) {
        _restartPlayback(bpm: next.toDouble());
      }
    });

    _loadInitialSettings();
    return MetronomeState.initial();
  }

  Future<void> _loadInitialSettings() async {
    try {
      final store = ref.read(settingsStoreProvider);
      final loaded = await store.loadMetronomeSettings();
      if (loaded != null) {
        state = state.copyWith(settings: loaded);
      }
    } catch (_) {
      // Store may not be overridden or access failed; retain initial defaults.
    }
  }

  /// Explicitly loads settings from the active [SettingsStore] and updates [state].
  Future<void> loadFromStore() => _loadInitialSettings();

  AudioEngine get _engine => ref.read(audioEngineProvider);
  MetronomeRenderer get _renderer => ref.read(metronomeRendererProvider);

  /// Updates settings, saves them to [SettingsStore], and swaps loop at boundary if currently playing.
  Future<void> updateSettings(MetronomeSettings newSettings) async {
    state = state.copyWith(settings: newSettings);
    await _saveSettingsToStore(newSettings);
    if (state.isPlaying) {
      await _restartPlayback(settings: newSettings);
    }
  }

  /// Sets beats per bar (1..16).
  Future<void> setBeatsPerBar(int beats) async {
    final updated = state.settings.copyWith(beatsPerBar: beats);
    await updateSettings(updated);
  }

  /// Toggles accented sound on the first beat.
  Future<void> toggleAccent() async {
    final updated = state.settings.copyWith(accent: !state.settings.accent);
    await updateSettings(updated);
  }

  /// Updates oscillator waveform (sine, triangle, square, saw, noise).
  Future<void> setWaveform(Waveform waveform) async {
    final updated = state.settings.copyWith(waveform: waveform);
    await updateSettings(updated);
  }

  /// Updates base pitch in Hz.
  Future<void> setPitchHz(double pitchHz) async {
    final updated = state.settings.copyWith(pitchHz: pitchHz);
    await updateSettings(updated);
  }

  /// Updates amplitude envelope decay time in ms.
  Future<void> setDecayMs(double decayMs) async {
    final updated = state.settings.copyWith(decayMs: decayMs);
    await updateSettings(updated);
  }

  /// Starts metronome looped playback using the current settings and tempo.
  Future<void> start() async {
    if (state.isPlaying) return;

    ref.read(sequencerControllerProvider.notifier).onExternalStop();

    final bpm = ref.read(tempoProvider).toDouble();
    final buffer = _renderer.renderBuffer(settings: state.settings, bpm: bpm);

    if (_engine.isPlaying) {
      await _engine.swapLoopAtBoundary(buffer);
    } else {
      await _engine.startLoop(buffer);
    }

    state = state.copyWith(isPlaying: true);
  }

  /// Ceases metronome playback immediately.
  Future<void> stop() async {
    if (!state.isPlaying) return;

    await _engine.stop();
    state = state.copyWith(isPlaying: false);
  }

  /// Toggles metronome playback between playing and stopped.
  Future<void> togglePlayback() async {
    if (state.isPlaying) {
      await stop();
    } else {
      await start();
    }
  }

  Future<void> _restartPlayback({double? bpm, MetronomeSettings? settings}) async {
    if (!state.isPlaying) return;

    final effectiveBpm = bpm ?? ref.read(tempoProvider).toDouble();
    final effectiveSettings = settings ?? state.settings;
    final buffer = _renderer.renderBuffer(
      settings: effectiveSettings,
      bpm: effectiveBpm,
    );

    await _engine.swapLoopAtBoundary(buffer);
  }

  Future<void> _saveSettingsToStore(MetronomeSettings settings) async {
    try {
      final store = ref.read(settingsStoreProvider);
      await store.saveMetronomeSettings(settings);
    } catch (_) {
      // Store may not be overridden or persistence failed.
    }
  }

  /// Invoked when external playback (such as the sequencer) starts or playback is stopped globally.
  void onExternalStop() {
    if (state.isPlaying) {
      state = state.copyWith(isPlaying: false);
    }
  }
}

/// Global provider for [MetronomeController].
final metronomeControllerProvider =
    NotifierProvider<MetronomeController, MetronomeState>(
        MetronomeController.new);
