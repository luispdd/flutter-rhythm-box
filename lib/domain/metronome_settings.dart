import 'package:flutter/foundation.dart';
import 'package:rhythm_box/domain/voice.dart';

/// Configuration settings for the metronome click.
///
/// Holds the number of beats per bar, beat 1 accent toggle, oscillator waveform,
/// base pitch in Hz, and click decay duration in milliseconds.
/// Instances are immutable value objects.
@immutable
class MetronomeSettings {
  /// Minimum allowed beats per bar.
  static const int minBeatsPerBar = 2;

  /// Maximum allowed beats per bar.
  static const int maxBeatsPerBar = 9;

  /// Default beats per bar.
  static const int defaultBeatsPerBar = 4;

  /// Minimum click pitch in Hz.
  static const double minPitchHz = 200.0;

  /// Maximum click pitch in Hz.
  static const double maxPitchHz = 4000.0;

  /// Default click pitch in Hz.
  static const double defaultPitchHz = 1000.0;

  /// Minimum click decay duration in milliseconds.
  static const double minDecayMs = 10.0;

  /// Maximum click decay duration in milliseconds.
  static const double maxDecayMs = 200.0;

  /// Default click decay duration in milliseconds.
  static const double defaultDecayMs = 40.0;

  /// Multiplier used to compute the accent click pitch from [pitchHz].
  static const double accentPitchMultiplier = 1.5;

  /// Default state for beat 1 accent.
  static const bool defaultAccent = true;

  /// Default synthesis waveform for the click tone.
  static const Waveform defaultWaveform = Waveform.sine;

  /// Default schema version for serialized metronome settings.
  static const int defaultSchemaVersion = 1;

  /// Schema version for serialization compatibility.
  final int schemaVersion;

  /// Number of beats per bar (clamped to 2..9).
  final int beatsPerBar;

  /// Whether beat 1 is played with an accented pitch.
  final bool accent;

  /// The waveform used to synthesize the click (sine, triangle, or square).
  final Waveform waveform;

  /// Pitch of normal clicks in Hz (clamped to 200..4000).
  final double pitchHz;

  /// Exponential decay duration in milliseconds (clamped to 10..200).
  final double decayMs;

  /// Creates a [MetronomeSettings] instance with clamped values.
  ///
  /// Throws an [ArgumentError] if [waveform] is [Waveform.noise], as noise
  /// is not a tonal click waveform.
  MetronomeSettings({
    this.schemaVersion = defaultSchemaVersion,
    int beatsPerBar = defaultBeatsPerBar,
    bool? accent,
    bool? accentOnBeat1,
    this.waveform = defaultWaveform,
    double? pitchHz,
    double? pitch,
    double? decayMs,
    double? decay,
  })  : beatsPerBar = clampBeatsPerBar(beatsPerBar),
        accent = accentOnBeat1 ?? accent ?? defaultAccent,
        pitchHz = clampPitchHz(pitchHz ?? pitch ?? defaultPitchHz),
        decayMs = clampDecayMs(decayMs ?? decay ?? defaultDecayMs) {
    if (waveform == Waveform.noise) {
      throw ArgumentError.value(
        waveform,
        'waveform',
        'Noise is not a supported metronome waveform. '
        'Supported waveforms are sine, triangle, and square.',
      );
    }
  }

  /// Alias for [accent].
  bool get accentOnBeat1 => accent;

  /// Alias for [pitchHz].
  double get pitch => pitchHz;

  /// Alias for [decayMs].
  double get decay => decayMs;

  /// The pitch in Hz used for accented beat 1 clicks (1.5 x [pitchHz]).
  double get accentPitchHz => pitchHz * accentPitchMultiplier;

  /// Alias for [accentPitchHz].
  double get accentPitch => accentPitchHz;

  /// Clamps an integer beat count to the valid range [2, 9].
  static int clampBeatsPerBar(int value) =>
      value.clamp(minBeatsPerBar, maxBeatsPerBar);

  /// Clamps a pitch in Hz to the valid range [200.0, 4000.0].
  static double clampPitchHz(num value) =>
      value.clamp(minPitchHz, maxPitchHz).toDouble();

  /// Clamps a decay duration in ms to the valid range [10.0, 200.0].
  static double clampDecayMs(num value) =>
      value.clamp(minDecayMs, maxDecayMs).toDouble();

  /// Returns a copy of these settings with specified fields updated.
  MetronomeSettings copyWith({
    int? schemaVersion,
    int? beatsPerBar,
    bool? accent,
    bool? accentOnBeat1,
    Waveform? waveform,
    double? pitchHz,
    double? pitch,
    double? decayMs,
    double? decay,
  }) {
    return MetronomeSettings(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      beatsPerBar: beatsPerBar ?? this.beatsPerBar,
      accent: accentOnBeat1 ?? accent ?? this.accent,
      waveform: waveform ?? this.waveform,
      pitchHz: pitchHz ?? pitch ?? this.pitchHz,
      decayMs: decayMs ?? decay ?? this.decayMs,
    );
  }

  /// Serializes these settings to a JSON-compatible map.
  Map<String, dynamic> toJson() => {
        'schemaVersion': schemaVersion,
        'beatsPerBar': beatsPerBar,
        'accent': accent,
        'waveform': waveform.name,
        'pitchHz': pitchHz,
        'decayMs': decayMs,
      };

  /// Deserializes [MetronomeSettings] from a JSON map.
  ///
  /// Missing or omitted fields fall back to their default values.
  /// Throws [ArgumentError] if [waveform] is [Waveform.noise] or an unknown waveform.
  factory MetronomeSettings.fromJson(Map<String, dynamic> json) {
    final schemaVersionRaw = json['schemaVersion'];
    final schemaVersion =
        schemaVersionRaw is num ? schemaVersionRaw.toInt() : defaultSchemaVersion;

    final beatsRaw = json['beatsPerBar'] ?? json['beats'];
    final beatsPerBar =
        beatsRaw is num ? beatsRaw.toInt() : defaultBeatsPerBar;

    final accentRaw = json['accent'] ?? json['accentOnBeat1'];
    final accent = accentRaw is bool ? accentRaw : defaultAccent;

    final waveformRaw = json['waveform'];
    Waveform waveform = defaultWaveform;
    if (waveformRaw is String) {
      waveform = Waveform.fromJson(waveformRaw);
    }

    final pitchRaw = json['pitchHz'] ?? json['pitch'];
    final pitchHz =
        pitchRaw is num ? pitchRaw.toDouble() : defaultPitchHz;

    final decayRaw = json['decayMs'] ?? json['decay'];
    final decayMs =
        decayRaw is num ? decayRaw.toDouble() : defaultDecayMs;

    return MetronomeSettings(
      schemaVersion: schemaVersion,
      beatsPerBar: beatsPerBar,
      accent: accent,
      waveform: waveform,
      pitchHz: pitchHz,
      decayMs: decayMs,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MetronomeSettings &&
          runtimeType == other.runtimeType &&
          other.schemaVersion == schemaVersion &&
          other.beatsPerBar == beatsPerBar &&
          other.accent == accent &&
          other.waveform == waveform &&
          other.pitchHz == pitchHz &&
          other.decayMs == decayMs;

  @override
  int get hashCode => Object.hash(
        schemaVersion,
        beatsPerBar,
        accent,
        waveform,
        pitchHz,
        decayMs,
      );

  @override
  String toString() =>
      'MetronomeSettings(schemaVersion: $schemaVersion, beatsPerBar: $beatsPerBar, accent: $accent, '
      'waveform: ${waveform.name}, pitch: ${pitchHz}Hz, decay: ${decayMs}ms)';
}
