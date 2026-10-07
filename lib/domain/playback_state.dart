/// Pure-Dart domain models representing playback state and pattern presets.
enum PlaybackMode {
  idle,
  sequencer,
  metronome,
}

/// Pattern presets for the spike sequencer.
enum PatternPreset {
  fourOnTheFloor('All 4 Steps (16ths)', [true, true, true, true]),
  alternating('Alternating (8ths)', [true, false, true, false]),
  syncopated('Syncopated [X X . X]', [true, true, false, true]),
  offBeat('Off-Beat [. X . X]', [false, true, false, true]);

  final String label;
  final List<bool> steps;
  const PatternPreset(this.label, this.steps);
}

/// Immutable state describing current playback configuration and activity.
class PlaybackState {
  final PlaybackMode mode;
  final double bpm;
  final PatternPreset patternPreset;
  final int beatsPerBar;
  final String lastEvent;

  const PlaybackState({
    this.mode = PlaybackMode.idle,
    this.bpm = 120.0,
    this.patternPreset = PatternPreset.fourOnTheFloor,
    this.beatsPerBar = 4,
    this.lastEvent = 'Ready',
  });

  bool get isPlaying => mode != PlaybackMode.idle;

  PlaybackState copyWith({
    PlaybackMode? mode,
    double? bpm,
    PatternPreset? patternPreset,
    int? beatsPerBar,
    String? lastEvent,
  }) {
    return PlaybackState(
      mode: mode ?? this.mode,
      bpm: bpm ?? this.bpm,
      patternPreset: patternPreset ?? this.patternPreset,
      beatsPerBar: beatsPerBar ?? this.beatsPerBar,
      lastEvent: lastEvent ?? this.lastEvent,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlaybackState &&
          runtimeType == other.runtimeType &&
          mode == other.mode &&
          bpm == other.bpm &&
          patternPreset == other.patternPreset &&
          beatsPerBar == other.beatsPerBar &&
          lastEvent == other.lastEvent;

  @override
  int get hashCode => Object.hash(mode, bpm, patternPreset, beatsPerBar, lastEvent);
}
