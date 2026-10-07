import 'package:flutter/foundation.dart';

/// Supported synthesis waveforms.
enum Waveform {
  sine,
  triangle,
  square,
  noise;

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

/// Sentinel used by [Voice.copyWith] to differentiate omitted arguments
/// from explicitly passing `null`.
const Object _sentinel = Object();

/// Parameters describing a synthesized voice.
@immutable
class Voice {
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

  /// Creates a [Voice] configuration.
  const Voice({
    required this.waveform,
    this.startFreqHz = 0.0,
    this.endFreqHz = 0.0,
    required this.decayMs,
    this.gain = 1.0,
    this.highpassHz,
    this.lowpassHz,
  });

  /// Returns a copy of this [Voice] with updated fields.
  Voice copyWith({
    Waveform? waveform,
    double? startFreqHz,
    double? endFreqHz,
    double? decayMs,
    double? gain,
    Object? highpassHz = _sentinel,
    Object? lowpassHz = _sentinel,
  }) {
    return Voice(
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
    );
  }

  /// Serializes this [Voice] to a JSON-compatible map.
  Map<String, dynamic> toJson() => {
        'waveform': waveform.name,
        'startFreqHz': startFreqHz,
        'endFreqHz': endFreqHz,
        'decayMs': decayMs,
        'gain': gain,
        'highpassHz': highpassHz,
        'lowpassHz': lowpassHz,
      };

  /// Deserializes a [Voice] from a JSON map.
  ///
  /// Throws an [ArgumentError] if required keys are missing or invalid.
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

    return Voice(
      waveform: waveform,
      startFreqHz: startFreqHz,
      endFreqHz: endFreqHz,
      decayMs: decayMs,
      gain: gain,
      highpassHz: highpassHz,
      lowpassHz: lowpassHz,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Voice &&
          runtimeType == other.runtimeType &&
          other.waveform == waveform &&
          other.startFreqHz == startFreqHz &&
          other.endFreqHz == endFreqHz &&
          other.decayMs == decayMs &&
          other.gain == gain &&
          other.highpassHz == highpassHz &&
          other.lowpassHz == lowpassHz;

  @override
  int get hashCode => Object.hash(
        waveform,
        startFreqHz,
        endFreqHz,
        decayMs,
        gain,
        highpassHz,
        lowpassHz,
      );

  @override
  String toString() =>
      'Voice(waveform: ${waveform.name}, sweep: ${startFreqHz}Hz->${endFreqHz}Hz, '
      'decay: ${decayMs}ms, gain: $gain, hp: $highpassHz, lp: $lowpassHz)';
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
    waveform: Waveform.sine,
    startFreqHz: 150.0,
    endFreqHz: 45.0,
    decayMs: 260.0,
    gain: 0.8,
  ),
  // Track 1: Low tom-like sine sweep
  Voice(
    waveform: Waveform.sine,
    startFreqHz: 120.0,
    endFreqHz: 70.0,
    decayMs: 200.0,
    gain: 0.8,
  ),
  // Track 2: Mid percussion triangle sweep
  Voice(
    waveform: Waveform.triangle,
    startFreqHz: 180.0,
    endFreqHz: 120.0,
    decayMs: 160.0,
    gain: 0.8,
  ),
  // Track 3: High percussion triangle sweep
  Voice(
    waveform: Waveform.triangle,
    startFreqHz: 260.0,
    endFreqHz: 200.0,
    decayMs: 140.0,
    gain: 0.8,
  ),
  // Track 4: Lower square synth hit
  Voice(
    waveform: Waveform.square,
    startFreqHz: 400.0,
    endFreqHz: 400.0,
    decayMs: 90.0,
    gain: 0.4,
  ),
  // Track 5: Higher square synth hit
  Voice(
    waveform: Waveform.square,
    startFreqHz: 800.0,
    endFreqHz: 800.0,
    decayMs: 70.0,
    gain: 0.4,
  ),
  // Track 6: Snare/hat-like filtered noise
  Voice(
    waveform: Waveform.noise,
    startFreqHz: 0.0,
    endFreqHz: 0.0,
    decayMs: 80.0,
    gain: 0.6,
    highpassHz: 3000.0,
  ),
  // Track 7: Hat-like high-passed noise
  Voice(
    waveform: Waveform.noise,
    startFreqHz: 0.0,
    endFreqHz: 0.0,
    decayMs: 40.0,
    gain: 0.6,
    highpassHz: 7000.0,
  ),
];
