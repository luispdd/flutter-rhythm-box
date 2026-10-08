import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../audio/audio_engine.dart';
import '../audio/background_audio_service.dart';
import '../domain/audio_buffer.dart';
import '../domain/pattern.dart';
import '../domain/sequence.dart';
import '../synth/pattern_renderer.dart';
import '../synth/synth_timing.dart';
import 'app_error.dart';
import 'metronome_controller.dart';
import 'pattern_library_notifier.dart';
import 'playback_controller.dart';
import 'sequencer_controller.dart';

/// Immutable state describing active sequence editing and playback.
@immutable
class SequenceState {
  final Sequence sequence;
  final bool isPlaying;
  final bool isLoading;
  final int currentEntryIndex;
  final AudioBuffer? currentBuffer;

  const SequenceState({
    required this.sequence,
    this.isPlaying = false,
    this.isLoading = false,
    this.currentEntryIndex = -1,
    this.currentBuffer,
  });

  factory SequenceState.initial() => SequenceState(
        sequence: Sequence.empty(),
      );

  SequenceState copyWith({
    Sequence? sequence,
    bool? isPlaying,
    bool? isLoading,
    int? currentEntryIndex,
    AudioBuffer? currentBuffer,
  }) {
    return SequenceState(
      sequence: sequence ?? this.sequence,
      isPlaying: isPlaying ?? this.isPlaying,
      isLoading: isLoading ?? this.isLoading,
      currentEntryIndex: currentEntryIndex ?? this.currentEntryIndex,
      currentBuffer: currentBuffer ?? this.currentBuffer,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SequenceState &&
          runtimeType == other.runtimeType &&
          sequence == other.sequence &&
          isPlaying == other.isPlaying &&
          isLoading == other.isLoading &&
          currentEntryIndex == other.currentEntryIndex &&
          currentBuffer == other.currentBuffer;

  @override
  int get hashCode => Object.hash(
        sequence,
        isPlaying,
        isLoading,
        currentEntryIndex,
        currentBuffer,
      );
}

/// Riverpod [Notifier] managing active sequence editing and playback.
class SequenceController extends Notifier<SequenceState> {
  StreamSubscription<Duration>? _positionSubscription;

  @override
  SequenceState build() {
    ref.onDispose(() {
      _positionSubscription?.cancel();
    });
    return SequenceState.initial();
  }

  AudioEngine get _engine => ref.read(audioEngineProvider);
  BackgroundAudioService get _backgroundService =>
      ref.read(backgroundAudioServiceProvider);

  /// Loads [sequence] into the active editor/controller.
  void setSequence(Sequence sequence) {
    if (state.isPlaying) {
      stop();
    }
    state = state.copyWith(sequence: sequence, currentEntryIndex: -1);
  }

  /// Updates the name of the active sequence.
  void updateName(String name) {
    state = state.copyWith(
      sequence: state.sequence.copyWith(name: name),
    );
  }

  /// Toggles loop mode between looping and play-once.
  void toggleLoop() {
    state = state.copyWith(
      sequence: state.sequence.copyWith(loop: !state.sequence.loop),
    );
  }

  /// Sets loop mode explicitly.
  void setLoop(bool loop) {
    state = state.copyWith(
      sequence: state.sequence.copyWith(loop: loop),
    );
  }

  /// Adds a new entry referencing [patternId] to the active sequence.
  void addEntry(String patternId, {int repeats = 1}) {
    final entry = SequenceEntry(patternId: patternId, repeats: repeats);
    final updatedEntries = [...state.sequence.entries, entry];
    state = state.copyWith(
      sequence: state.sequence.copyWith(entries: updatedEntries),
    );
  }

  /// Removes the entry at [index].
  void removeEntry(int index) {
    if (index < 0 || index >= state.sequence.entries.length) return;
    final updatedEntries = List<SequenceEntry>.from(state.sequence.entries)
      ..removeAt(index);
    state = state.copyWith(
      sequence: state.sequence.copyWith(entries: updatedEntries),
    );
  }

  /// Reorders entries (adjusting for Flutter ReorderableListView semantics).
  void reorderEntries(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= state.sequence.entries.length) return;
    final entries = List<SequenceEntry>.from(state.sequence.entries);
    var targetIndex = newIndex;
    if (oldIndex < targetIndex) {
      targetIndex -= 1;
    }
    if (targetIndex < 0 || targetIndex >= entries.length) return;
    final item = entries.removeAt(oldIndex);
    entries.insert(targetIndex, item);
    state = state.copyWith(
      sequence: state.sequence.copyWith(entries: entries),
    );
  }

  /// Sets the repeats count for entry at [index].
  void setEntryRepeats(int index, int repeats) {
    if (index < 0 || index >= state.sequence.entries.length) return;
    final entries = List<SequenceEntry>.from(state.sequence.entries);
    entries[index] = entries[index].copyWith(repeats: repeats);
    state = state.copyWith(
      sequence: state.sequence.copyWith(entries: entries),
    );
  }

  /// Starts sequence playback.
  Future<void> start() async {
    if (state.isPlaying || state.isLoading) return;
    if (state.sequence.entries.isEmpty) return;

    state = state.copyWith(isLoading: true);

    // Mutual exclusivity: stop metronome and pattern sequencer
    ref.read(metronomeControllerProvider.notifier).onExternalStop();
    ref.read(sequencerControllerProvider.notifier).onExternalStop();

    final patterns = ref.read(patternLibraryProvider);
    final patternMap = {for (final p in patterns) p.id: p};

    try {
      final buffer = await PatternRenderer.renderSequenceBufferCompute(
        sequence: state.sequence,
        patterns: patternMap,
      );

      if (buffer.totalSamples == 0) {
        state = state.copyWith(isLoading: false);
        return;
      }

      await _engine.startLoop(buffer, looping: state.sequence.loop);

      state = state.copyWith(
        isPlaying: true,
        isLoading: false,
        currentBuffer: buffer,
        currentEntryIndex: 0,
      );

      ref.read(audioErrorProvider.notifier).clear();
      _subscribeToPositionStream(buffer, patternMap);
      unawaited(_backgroundService.start());
    } catch (e) {
      state = state.copyWith(isLoading: false, isPlaying: false);
      final msg = 'Audio playback failed: $e';
      ref.read(audioErrorProvider.notifier).setError(msg);
      showAppSnackBar(msg);
    }
  }

  /// Ceases sequence playback immediately.
  Future<void> stop() async {
    _positionSubscription?.cancel();
    _positionSubscription = null;

    if (state.isPlaying) {
      await _engine.stop();
      unawaited(_backgroundService.stop());
    }
    state = state.copyWith(
      isPlaying: false,
      isLoading: false,
      currentEntryIndex: -1,
    );
  }

  /// Toggles playback between playing and stopped.
  Future<void> togglePlay() async {
    if (state.isPlaying) {
      await stop();
    } else {
      await start();
    }
  }

  /// Invoked when external playback (metronome or sequencer) starts.
  void onExternalStop() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
    if (state.isPlaying || state.isLoading) {
      state = state.copyWith(
        isPlaying: false,
        isLoading: false,
        currentEntryIndex: -1,
      );
    }
  }

  void _subscribeToPositionStream(
    AudioBuffer buffer,
    Map<String, Pattern> patternMap,
  ) {
    _positionSubscription?.cancel();
    final stream = _engine.positionStream;
    if (stream == null) return;

    const timing = SynthTiming(sampleRate: SynthTiming.defaultSampleRate);

    // Calculate durations for each valid entry
    final entryDurationsUs = <int>[];
    var totalSeqUs = 0;
    for (final entry in state.sequence.entries) {
      final pat = patternMap[entry.patternId];
      if (pat == null) {
        entryDurationsUs.add(0);
        continue;
      }
      final loopSamples = timing.loopLengthSamples(pat.stepCount, pat.tempoBpm.toDouble());
      final entrySamples = loopSamples * entry.repeats;
      final durUs = (entrySamples * 1000000 / SynthTiming.defaultSampleRate).round();
      entryDurationsUs.add(durUs);
      totalSeqUs += durUs;
    }

    _positionSubscription = stream.listen((position) {
      if (!state.isPlaying) return;

      final posUs = position.inMicroseconds;
      if (!state.sequence.loop && totalSeqUs > 0 && posUs >= totalSeqUs) {
        unawaited(stop());
        return;
      }

      if (totalSeqUs == 0) return;

      final normalizedPosUs = posUs % totalSeqUs;
      var cumulativeUs = 0;
      var foundIndex = 0;
      for (var i = 0; i < entryDurationsUs.length; i++) {
        final dur = entryDurationsUs[i];
        if (dur <= 0) continue;
        if (normalizedPosUs < cumulativeUs + dur) {
          foundIndex = i;
          break;
        }
        cumulativeUs += dur;
      }

      if (state.currentEntryIndex != foundIndex) {
        state = state.copyWith(currentEntryIndex: foundIndex);
      }
    });
  }
}

/// Global provider for [SequenceController].
final sequenceControllerProvider =
    NotifierProvider<SequenceController, SequenceState>(
        SequenceController.new);
