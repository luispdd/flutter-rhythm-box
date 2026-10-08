import 'package:flutter/foundation.dart';

/// Supported synthesis waveforms.
enum Waveform {
  sine,
  triangle,
  square,
  pulse,
  noise,
  lfsrNoise;

  /// Parses a waveform from its JSON string representation.
  ///
  /// Throws an [ArgumentError] if [value] does not match any supported waveform.
  static Waveform fromJson(String value) {
    for (final wave in Waveform.values) {
      if (wave.name.toLowerCase() == value.toLowerCase()) {
        return wave;
      }
    }
    throw ArgumentError.value(
      value,
      'waveform',
      'Unknown waveform "$value". Supported waveforms are: '
          '${Waveform.values.map((w) => w.name).join(', ')}.',
    );
  }

  /// Serializes the waveform to its string name.
  String toJson() => name;
}

/// Stepped pitch definition for arpeggios, coin blips, and frequency shifts.
@immutable
class PitchSteps {
  /// Semitone offsets relative to base [Voice.startFreqHz].
  final List<int> semitones;

  /// Duration each step is held in milliseconds.
  final double stepMs;

  const PitchSteps({
    required this.semitones,
    required this.stepMs,
  });

  /// Serializes to a JSON map.
  Map<String, dynamic> toJson() => {
        'semitones': semitones,
        'stepMs': stepMs,
      };

  /// Deserializes from a JSON map.
  factory PitchSteps.fromJson(Map<String, dynamic> json) {
    final semitonesRaw = json['semitones'];
    if (semitonesRaw is! List) {
      throw ArgumentError.value(
        semitonesRaw,
        'semitones',
        'Missing or invalid "semitones" in PitchSteps JSON.',
      );
    }
    final semitones = semitonesRaw
        .map((e) => (e as num).toInt())
        .toList(growable: false);

    final stepMsRaw = json['stepMs'];
    if (stepMsRaw is! num || stepMsRaw <= 0) {
      throw ArgumentError.value(
        stepMsRaw,
        'stepMs',
        'Missing or invalid positive "stepMs" in PitchSteps JSON.',
      );
    }

    return PitchSteps(
      semitones: semitones,
      stepMs: stepMsRaw.toDouble(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PitchSteps &&
          runtimeType == other.runtimeType &&
          listEquals(other.semitones, semitones) &&
          other.stepMs == stepMs;

  @override
  int get hashCode => Object.hash(Object.hashAll(semitones), stepMs);

  @override
  String toString() => 'PitchSteps(semitones: $semitones, stepMs: ${stepMs}ms)';
}

/// Sentinel used by [Voice.copyWith] to differentiate omitted arguments
/// from explicitly passing `null`.
const Object _sentinel = Object();

/// Parameters describing a synthesized voice.
@immutable
class Voice {
  /// Human-readable name shown on track rows (e.g., "Kick").
  final String? label;

  /// The base oscillator or generator waveform.
  final Waveform waveform;

  /// Starting frequency in Hz for the frequency sweep.
  final double startFreqHz;

  /// Ending frequency in Hz for the frequency sweep.
  final double endFreqHz;

  /// Exponential decay duration in milliseconds.
  final double decayMs;

  /// Per-voice gain factor (linear scale).
  final double gain;

  /// Optional high-pass filter cutoff frequency in Hz.
  final double? highpassHz;

  /// Optional low-pass filter cutoff frequency in Hz.
  final double? lowpassHz;

  /// Duty cycle for [Waveform.pulse] (0.05 to 0.95, default 0.5).
  final double? dutyCycle;

  /// Clock rate in Hz for [Waveform.lfsrNoise] (e.g. 2000 to 48000).
  final double? lfsrClockHz;

  /// Short (7-bit / 93-step periodic) mode flag for [Waveform.lfsrNoise].
  final bool? lfsrShort;

  /// Stepped pitch sequence overriding continuous frequency sweep.
  final PitchSteps? pitchSteps;

  /// Bit depth quantization (2 to 16, null = disabled).
  final int? bitDepth;

  /// Downsampling sample-and-hold rate in Hz (null = disabled).
  final double? downsampleHz;

  /// Creates a [Voice] configuration.
  const Voice({
    this.label,
    required this.waveform,
    this.startFreqHz = 0.0,
    this.endFreqHz = 0.0,
    required this.decayMs,
    this.gain = 1.0,
    this.highpassHz,
    this.lowpassHz,
    this.dutyCycle,
    this.lfsrClockHz,
    this.lfsrShort,
    this.pitchSteps,
    this.bitDepth,
    this.downsampleHz,
  });

  /// Returns a copy of this [Voice] with updated fields.
  Voice copyWith({
    Object? label = _sentinel,
    Waveform? waveform,
    double? startFreqHz,
    double? endFreqHz,
    double? decayMs,
    double? gain,
    Object? highpassHz = _sentinel,
    Object? lowpassHz = _sentinel,
    Object? dutyCycle = _sentinel,
    Object? lfsrClockHz = _sentinel,
    Object? lfsrShort = _sentinel,
    Object? pitchSteps = _sentinel,
    Object? bitDepth = _sentinel,
    Object? downsampleHz = _sentinel,
  }) {
    return Voice(
      label: identical(label, _sentinel) ? this.label : label as String?,
      waveform: waveform ?? this.waveform,
      startFreqHz: startFreqHz ?? this.startFreqHz,
      endFreqHz: endFreqHz ?? this.endFreqHz,
      decayMs: decayMs ?? this.decayMs,
      gain: gain ?? this.gain,
      highpassHz: identical(highpassHz, _sentinel)
          ? this.highpassHz
          : highpassHz as double?,
      lowpassHz: identical(lowpassHz, _sentinel)
          ? this.lowpassHz
          : lowpassHz as double?,
      dutyCycle: identical(dutyCycle, _sentinel)
          ? this.dutyCycle
          : dutyCycle as double?,
      lfsrClockHz: identical(lfsrClockHz, _sentinel)
          ? this.lfsrClockHz
          : lfsrClockHz as double?,
      lfsrShort: identical(lfsrShort, _sentinel)
          ? this.lfsrShort
          : lfsrShort as bool?,
      pitchSteps: identical(pitchSteps, _sentinel)
          ? this.pitchSteps
          : pitchSteps as PitchSteps?,
      bitDepth: identical(bitDepth, _sentinel)
          ? this.bitDepth
          : bitDepth as int?,
      downsampleHz: identical(downsampleHz, _sentinel)
          ? this.downsampleHz
          : downsampleHz as double?,
    );
  }

  /// Serializes this [Voice] to a JSON-compatible map.
  Map<String, dynamic> toJson() => {
        if (label != null) 'label': label,
        'waveform': waveform.name,
        'startFreqHz': startFreqHz,
        'endFreqHz': endFreqHz,
        'decayMs': decayMs,
        'gain': gain,
        'highpassHz': highpassHz,
        'lowpassHz': lowpassHz,
        if (dutyCycle != null) 'dutyCycle': dutyCycle,
        if (lfsrClockHz != null) 'lfsrClockHz': lfsrClockHz,
        if (lfsrShort != null) 'lfsrShort': lfsrShort,
        if (pitchSteps != null) 'pitchSteps': pitchSteps!.toJson(),
        if (bitDepth != null) 'bitDepth': bitDepth,
        if (downsampleHz != null) 'downsampleHz': downsampleHz,
      };

  /// Deserializes a [Voice] from a JSON map.
  factory Voice.fromJson(Map<String, dynamic> json) {
    final waveformRaw = json['waveform'];
    if (waveformRaw is! String) {
      throw ArgumentError.value(
        waveformRaw,
        'waveform',
        'Missing or invalid "waveform" property in Voice JSON: $waveformRaw',
      );
    }
    final waveform = Waveform.fromJson(waveformRaw);

    final startFreqRaw = json['startFreqHz'];
    final startFreqHz = startFreqRaw is num ? startFreqRaw.toDouble() : 0.0;

    final endFreqRaw = json['endFreqHz'];
    final endFreqHz = endFreqRaw is num ? endFreqRaw.toDouble() : 0.0;

    final decayMsRaw = json['decayMs'];
    if (decayMsRaw is! num) {
      throw ArgumentError.value(
        decayMsRaw,
        'decayMs',
        'Missing or invalid "decayMs" in Voice JSON: $decayMsRaw',
      );
    }
    final decayMs = decayMsRaw.toDouble();

    final gainRaw = json['gain'];
    final gain = gainRaw is num ? gainRaw.toDouble() : 1.0;

    final highpassRaw = json['highpassHz'];
    final highpassHz = highpassRaw is num ? highpassRaw.toDouble() : null;

    final lowpassRaw = json['lowpassHz'];
    final lowpassHz = lowpassRaw is num ? lowpassRaw.toDouble() : null;

    final label = json['label'] as String?;

    final dutyCycleRaw = json['dutyCycle'];
    final dutyCycle = dutyCycleRaw is num ? dutyCycleRaw.toDouble() : null;

    final lfsrClockRaw = json['lfsrClockHz'];
    final lfsrClockHz = lfsrClockRaw is num ? lfsrClockRaw.toDouble() : null;

    final lfsrShort = json['lfsrShort'] as bool?;

    final pitchStepsRaw = json['pitchSteps'];
    final pitchSteps = pitchStepsRaw is Map<String, dynamic>
        ? PitchSteps.fromJson(pitchStepsRaw)
        : null;

    final bitDepthRaw = json['bitDepth'];
    final bitDepth = bitDepthRaw is num ? bitDepthRaw.toInt() : null;

    final downsampleRaw = json['downsampleHz'];
    final downsampleHz = downsampleRaw is num ? downsampleRaw.toDouble() : null;

    return Voice(
      label: label,
      waveform: waveform,
      startFreqHz: startFreqHz,
      endFreqHz: endFreqHz,
      decayMs: decayMs,
      gain: gain,
      highpassHz: highpassHz,
      lowpassHz: lowpassHz,
      dutyCycle: dutyCycle,
      lfsrClockHz: lfsrClockHz,
      lfsrShort: lfsrShort,
      pitchSteps: pitchSteps,
      bitDepth: bitDepth,
      downsampleHz: downsampleHz,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Voice &&
          runtimeType == other.runtimeType &&
          other.label == label &&
          other.waveform == waveform &&
          other.startFreqHz == startFreqHz &&
          other.endFreqHz == endFreqHz &&
          other.decayMs == decayMs &&
          other.gain == gain &&
          other.highpassHz == highpassHz &&
          other.lowpassHz == lowpassHz &&
          other.dutyCycle == dutyCycle &&
          other.lfsrClockHz == lfsrClockHz &&
          other.lfsrShort == lfsrShort &&
          other.pitchSteps == pitchSteps &&
          other.bitDepth == bitDepth &&
          other.downsampleHz == downsampleHz;

  @override
  int get hashCode => Object.hash(
        label,
        waveform,
        startFreqHz,
        endFreqHz,
        decayMs,
        gain,
        highpassHz,
        lowpassHz,
        dutyCycle,
        lfsrClockHz,
        lfsrShort,
        pitchSteps,
        bitDepth,
        downsampleHz,
      );

  @override
  String toString() =>
      'Voice(label: $label, waveform: ${waveform.name}, sweep: ${startFreqHz}Hz->${endFreqHz}Hz, '
      'decay: ${decayMs}ms, gain: $gain, hp: $highpassHz, lp: $lowpassHz, '
      'duty: $dutyCycle, lfsrClock: $lfsrClockHz, lfsrShort: $lfsrShort, '
      'pitchSteps: $pitchSteps, bitDepth: $bitDepth, downsample: $downsampleHz)';
}

/// The fixed default ladder of 8 voices (track 0 lowest, track 7 highest).
///
/// Parameters from the specification table, with track gains from design decision D8:
/// - Tracks 0-3: gain 0.8
/// - Tracks 4-5: gain 0.4 (square wave attenuation)
/// - Tracks 6-7: gain 0.6 (noise attenuation)
const List<Voice> defaultVoices = [
  // Track 0: Kick-like sine sweep
  Voice(
    label: 'Kick',
    waveform: Waveform.sine,
    startFreqHz: 150.0,
    endFreqHz: 45.0,
    decayMs: 260.0,
    gain: 0.8,
  ),
  // Track 1: Low tom-like sine sweep
  Voice(
    label: 'Low tom',
    waveform: Waveform.sine,
    startFreqHz: 120.0,
    endFreqHz: 70.0,
    decayMs: 200.0,
    gain: 0.8,
  ),
  // Track 2: Mid percussion triangle sweep
  Voice(
    label: 'Mid perc',
    waveform: Waveform.triangle,
    startFreqHz: 180.0,
    endFreqHz: 120.0,
    decayMs: 160.0,
    gain: 0.8,
  ),
  // Track 3: High percussion triangle sweep
  Voice(
    label: 'High perc',
    waveform: Waveform.triangle,
    startFreqHz: 260.0,
    endFreqHz: 200.0,
    decayMs: 140.0,
    gain: 0.8,
  ),
  // Track 4: Lower square synth hit
  Voice(
    label: 'Low synth',
    waveform: Waveform.square,
    startFreqHz: 400.0,
    endFreqHz: 400.0,
    decayMs: 90.0,
    gain: 0.4,
  ),
  // Track 5: Higher square synth hit
  Voice(
    label: 'High synth',
    waveform: Waveform.square,
    startFreqHz: 800.0,
    endFreqHz: 800.0,
    decayMs: 70.0,
    gain: 0.4,
  ),
  // Track 6: Snare/hat-like filtered noise
  Voice(
    label: 'Snare',
    waveform: Waveform.noise,
    startFreqHz: 0.0,
    endFreqHz: 0.0,
    decayMs: 80.0,
    gain: 0.6,
    highpassHz: 3000.0,
  ),
  // Track 7: Hat-like high-passed noise
  Voice(
    label: 'Hat',
    waveform: Waveform.noise,
    startFreqHz: 0.0,
    endFreqHz: 0.0,
    decayMs: 40.0,
    gain: 0.6,
    highpassHz: 7000.0,
  ),
];
