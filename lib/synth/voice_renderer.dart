import 'dart:math' as math;
import 'dart:typed_data';

import '../domain/voice.dart';

/// Pure-Dart voice synthesizer rendering individual voices into audio buffers.
///
/// Follows Design D1–D7:
/// - Waveforms: sine, triangle, square, pulse, noise, lfsrNoise.
/// - Phase accumulated from instantaneous frequency sweep or stepped pitch (pitchSteps).
/// - Envelope: linear attack of 1.5 ms, then exponential decay `exp(-t / tau)`
///   with tau set so the amplitude is ~60 dB down at decayMs.
/// - Sample-rate reduction (downsampleHz) and bit crushing (bitDepth) applied
///   before digital filtering and envelope stages.
/// - Deterministic noise with seeded PRNG / LFSR per kit ID and track index.
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

  /// Deterministic seed derived from kit ID and track index.
  static int seedForKitAndTrack(String? kitId, int trackIndex) {
    if (kitId == null || kitId == 'classic-synth') {
      return defaultSeedForTrack(trackIndex);
    }
    return (kitId.hashCode & 0x7FFFFFFF) ^ (trackIndex * 31337);
  }

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
    String? kitId,
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

    final effectiveSeed = seed ?? seedForKitAndTrack(kitId, trackIndex);

    final isWhiteNoise = voice.waveform == Waveform.noise;
    final isLfsrNoise = voice.waveform == Waveform.lfsrNoise;
    final random = isWhiteNoise ? math.Random(effectiveSeed) : null;

    // NES LFSR setup
    var lfsrReg = 1;
    final lfsrClock = (voice.lfsrClockHz ?? 16000.0).clamp(100.0, 48000.0);
    final isLfsrShort = voice.lfsrShort == true;
    var currentLfsrStep = 0;

    final hasPitchSteps = voice.pitchSteps != null &&
        voice.pitchSteps!.semitones.isNotEmpty;
    final hasSweep = !isWhiteNoise &&
        !isLfsrNoise &&
        !hasPitchSteps &&
        voice.startFreqHz > 0 &&
        voice.endFreqHz > 0 &&
        voice.decayMs > 0;
    final sweepRatio = hasSweep ? voice.endFreqHz / voice.startFreqHz : 1.0;
    final lnSweepRatio = hasSweep ? math.log(sweepRatio) : 0.0;

    // Downsample setup
    final hasDownsample = voice.downsampleHz != null &&
        voice.downsampleHz! > 0 &&
        voice.downsampleHz! < sampleRate;
    final downsampleHz = voice.downsampleHz ?? 0.0;
    var lastDsStep = -1;
    var heldSample = 0.0;

    // Bit depth setup
    final hasBitDepth =
        voice.bitDepth != null && voice.bitDepth! >= 2 && voice.bitDepth! <= 16;
    final bitDepthLevels = hasBitDepth ? (1 << voice.bitDepth!) : 0;
    final bitDepthStep =
        hasBitDepth ? (2.0 / (bitDepthLevels - 1)) : 0.0;

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
      if (isWhiteNoise) {
        rawSample = random!.nextDouble() * 2.0 - 1.0;
      } else if (isLfsrNoise) {
        final targetLfsrStep =
            ((n * lfsrClock) / sampleRate + 1e-9).floor();
        while (currentLfsrStep < targetLfsrStep) {
          final feedback = isLfsrShort
              ? ((lfsrReg & 1) ^ ((lfsrReg >> 6) & 1))
              : ((lfsrReg & 1) ^ ((lfsrReg >> 1) & 1));
          lfsrReg = ((lfsrReg >> 1) | (feedback << 14)) & 0x7FFF;
          currentLfsrStep++;
        }
        rawSample = (lfsrReg & 1) == 0 ? 1.0 : -1.0;
      } else {
        double freq;
        if (hasPitchSteps) {
          final steps = voice.pitchSteps!;
          final stepSec = math.max(0.001, steps.stepMs / 1000.0);
          final stepIndex = (t / stepSec).floor();
          final semitone = stepIndex < steps.semitones.length
              ? steps.semitones[stepIndex]
              : steps.semitones.last;
          freq = voice.startFreqHz * math.pow(2.0, semitone / 12.0);
        } else if (hasSweep) {
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
          case Waveform.pulse:
            final u = (phase / twoPi) % 1.0;
            final duty = (voice.dutyCycle ?? 0.5).clamp(0.05, 0.95);
            rawSample = u < duty ? 1.0 : -1.0;
            break;
          case Waveform.noise:
          case Waveform.lfsrNoise:
            rawSample = 0.0;
            break;
        }

        phase += twoPi * freq / sampleRate;
        if (phase >= twoPi) {
          phase %= twoPi;
        }
      }

      // 3. Sample-rate reduction (downsampling)
      double processed = rawSample;
      if (hasDownsample) {
        final dsStep = ((n * downsampleHz) / sampleRate + 1e-9).floor();
        if (dsStep != lastDsStep) {
          heldSample = rawSample;
          lastDsStep = dsStep;
        }
        processed = heldSample;
      }

      // 4. Bit depth quantization (bit crushing)
      if (hasBitDepth) {
        processed = ((((processed + 1.0) / bitDepthStep).round() *
                    bitDepthStep) -
                1.0)
            .clamp(-1.0, 1.0);
      }

      // 5. Digital filtering
      double filtered = processed;
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

      // 6. Multiply by envelope and gain
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
    String? kitId,
  }) {
    final floatSamples = renderVoice(
      voice,
      totalSamples: totalSamples,
      durationSec: durationSec,
      trackIndex: trackIndex,
      seed: seed,
      kitId: kitId,
    );

    final pcm = Int16List(floatSamples.length);
    for (var i = 0; i < floatSamples.length; i++) {
      final limited = softLimit(floatSamples[i]);
      pcm[i] = (limited * 32767.0).clamp(-32768.0, 32767.0).round();
    }
    return pcm;
  }
}
