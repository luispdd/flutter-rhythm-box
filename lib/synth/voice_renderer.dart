import 'dart:math' as math;
import 'dart:typed_data';

import '../domain/voice.dart';

/// Pure-Dart voice synthesizer rendering individual voices into audio buffers.
///
/// Follows Design D5, D6, D7:
/// - Waveforms: sine, triangle, square, noise.
/// - Phase accumulated from instantaneous frequency sweep:
///   `f(t) = start * (end / start) ^ (t / len)`.
/// - Envelope: linear attack of 1.5 ms, then exponential decay `exp(-t / tau)`
///   with tau set so the amplitude is ~60 dB down at decayMs.
/// - Deterministic noise with seeded PRNG per track index.
/// - Digital one-pole high-pass and low-pass filters using bilinear transform.
class VoiceRenderer {
  /// Default audio sampling rate in Hz.
  static const int defaultSampleRate = 44100;

  /// Attack time in seconds (1.5 ms).
  static const double attackTimeSec = 0.0015;

  /// Natural log of 1000 (~6.907755), giving 60 dB attenuation at decayMs.
  static const double ln1000 = 6.907755278982137;

  final int sampleRate;

  const VoiceRenderer({this.sampleRate = defaultSampleRate});

  /// Deterministic seed for a given track index.
  static int defaultSeedForTrack(int trackIndex) =>
      0x12345678 ^ (trackIndex * 31337);

  /// Hyperbolic tangent soft limiter for mixing.
  static double softLimit(double x) {
    if (x > 20.0) return 1.0;
    if (x < -20.0) return -1.0;
    final e2x = math.exp(2.0 * x);
    return (e2x - 1.0) / (e2x + 1.0);
  }

  /// Renders a single [Voice] hit into a [Float64List].
  ///
  /// Output samples are scaled by [voice.gain].
  Float64List renderVoice(
    Voice voice, {
    int? totalSamples,
    double? durationSec,
    int trackIndex = 0,
    int? seed,
  }) {
    final numSamples = totalSamples ??
        ((durationSec ?? ((voice.decayMs * 5.0 + 10.0) / 1000.0)) *
                sampleRate)
            .round();

    if (numSamples <= 0) {
      return Float64List(0);
    }

    final output = Float64List(numSamples);
    final decaySec = math.max(0.001, voice.decayMs / 1000.0);
    final tau = decaySec / ln1000;

    final isNoise = voice.waveform == Waveform.noise;
    final random = isNoise
        ? math.Random(seed ?? defaultSeedForTrack(trackIndex))
        : null;

    final hasSweep = !isNoise &&
        voice.startFreqHz > 0 &&
        voice.endFreqHz > 0 &&
        voice.decayMs > 0;
    final sweepRatio = hasSweep ? voice.endFreqHz / voice.startFreqHz : 1.0;
    final lnSweepRatio = hasSweep ? math.log(sweepRatio) : 0.0;

    // Filter setup
    final hasHighpass = voice.highpassHz != null && voice.highpassHz! > 0;
    final hpCutoff = hasHighpass
        ? voice.highpassHz!.clamp(1.0, sampleRate * 0.499)
        : 0.0;
    final hpK = hasHighpass ? math.tan(math.pi * hpCutoff / sampleRate) : 0.0;
    final hpA0 = hasHighpass ? 1.0 / (1.0 + hpK) : 0.0;
    final hpB1 = hasHighpass ? (1.0 - hpK) / (1.0 + hpK) : 0.0;

    final hasLowpass = voice.lowpassHz != null && voice.lowpassHz! > 0;
    final lpCutoff = hasLowpass
        ? voice.lowpassHz!.clamp(1.0, sampleRate * 0.499)
        : 0.0;
    final lpK = hasLowpass ? math.tan(math.pi * lpCutoff / sampleRate) : 0.0;
    final lpA0 = hasLowpass ? lpK / (1.0 + lpK) : 0.0;
    final lpB1 = hasLowpass ? (1.0 - lpK) / (1.0 + lpK) : 0.0;

    double phase = 0.0;
    double hpXPrev = 0.0;
    double hpYPrev = 0.0;
    double lpXPrev = 0.0;
    double lpYPrev = 0.0;

    final twoPi = 2.0 * math.pi;

    for (var n = 0; n < numSamples; n++) {
      final t = n / sampleRate;

      // 1. Envelope calculation
      double env;
      if (t < attackTimeSec) {
        env = t / attackTimeSec;
      } else {
        env = math.exp(-(t - attackTimeSec) / tau);
      }

      // 2. Raw oscillator/generator output
      double rawSample;
      if (isNoise) {
        rawSample = random!.nextDouble() * 2.0 - 1.0;
      } else {
        double freq;
        if (hasSweep) {
          final alpha = (t / decaySec).clamp(0.0, 1.0);
          freq = voice.startFreqHz * math.exp(alpha * lnSweepRatio);
        } else {
          freq = voice.startFreqHz;
        }

        switch (voice.waveform) {
          case Waveform.sine:
            rawSample = math.sin(phase);
            break;
          case Waveform.triangle:
            final u = (phase / twoPi) % 1.0;
            rawSample = u < 0.25
                ? 4.0 * u
                : (u < 0.75 ? 2.0 - 4.0 * u : 4.0 * u - 4.0);
            break;
          case Waveform.square:
            final u = (phase / twoPi) % 1.0;
            rawSample = u < 0.5 ? 1.0 : -1.0;
            break;
          case Waveform.noise:
            rawSample = 0.0;
            break;
        }

        phase += twoPi * freq / sampleRate;
        if (phase >= twoPi) {
          phase %= twoPi;
        }
      }

      // 3. Digital filtering
      double filtered = rawSample;
      if (hasHighpass) {
        final y = hpA0 * (filtered - hpXPrev) + hpB1 * hpYPrev;
        hpXPrev = filtered;
        hpYPrev = y;
        filtered = y;
      }
      if (hasLowpass) {
        final y = lpA0 * (filtered + lpXPrev) + lpB1 * lpYPrev;
        lpXPrev = filtered;
        lpYPrev = y;
        filtered = y;
      }

      // 4. Multiply by envelope and gain
      output[n] = filtered * env * voice.gain;
    }

    return output;
  }

  /// Renders a single [Voice] hit into a 16-bit mono PCM [Int16List].
  Int16List renderVoicePcm(
    Voice voice, {
    int? totalSamples,
    double? durationSec,
    int trackIndex = 0,
    int? seed,
  }) {
    final floatSamples = renderVoice(
      voice,
      totalSamples: totalSamples,
      durationSec: durationSec,
      trackIndex: trackIndex,
      seed: seed,
    );

    final pcm = Int16List(floatSamples.length);
    for (var i = 0; i < floatSamples.length; i++) {
      final limited = softLimit(floatSamples[i]);
      pcm[i] = (limited * 32767.0).clamp(-32768.0, 32767.0).round();
    }
    return pcm;
  }
}
