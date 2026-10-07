import 'dart:math' as math;
import 'dart:typed_data';

import '../domain/audio_buffer.dart';
import 'synth_timing.dart';

/// Pure-Dart audio synthesizer and buffer renderer.
///
/// Follows Design D2:
/// - stepsPerBeat = 4
/// - Onset of step i at `round(i * samplesPerStep)`
/// - Loop length `round(stepCount * samplesPerStep)`
/// - Non-cumulative rounding guarantees sample-accurate timing across loop boundaries.
class ClickSynthesizer {
  /// Default audio sampling rate in Hz.
  static const int defaultSampleRate = 44100;

  /// Constant steps per beat (16th notes in 4/4 time).
  static const int stepsPerBeat = 4;

  final int sampleRate;

  const ClickSynthesizer({this.sampleRate = defaultSampleRate});

  SynthTiming get timing => SynthTiming(sampleRate: sampleRate);

  /// Computes the exact number of audio samples per 16th-note step for a given BPM.
  double calculateSamplesPerStep(double bpm) => timing.samplesPerStep(bpm);

  /// Calculates the onset sample index for step [stepIndex] at tempo [bpm].
  ///
  /// Uses Design D2 rounding rule: `round(i * samplesPerStep)`.
  int onsetSampleForStep(int stepIndex, double bpm) =>
      timing.onsetSampleForStep(stepIndex, bpm);

  /// Calculates the total loop length in samples for [stepCount] steps at tempo [bpm].
  ///
  /// Uses Design D2 rounding rule: `round(stepCount * samplesPerStep)`.
  int loopLengthSamples(int stepCount, double bpm) =>
      timing.loopLengthSamples(stepCount, bpm);

  /// Calculates the onset indices for all steps from 0 to [stepCount] - 1.
  List<int> calculateOnsetIndices(int stepCount, double bpm) =>
      timing.calculateStepOnsetIndices(stepCount, bpm);

  /// Generates a short, sharp click waveform kernel (16-bit PCM).
  ///
  /// Default: 2.5 ms burst of 2000 Hz sine wave with exponential decay.
  Int16List generateClickKernel({
    double frequencyHz = 2000.0,
    double durationSec = 0.003,
    double decayTimeSec = 0.0006,
    double amplitude = 0.8,
  }) {
    final numSamples = math.max(2, (durationSec * sampleRate).round());
    final kernel = Int16List(numSamples);
    final maxAmp = amplitude * 32767.0;

    for (var n = 0; n < numSamples; n++) {
      final t = n / sampleRate;
      final val = maxAmp *
          math.sin(2.0 * math.pi * frequencyHz * t) *
          math.exp(-t / decayTimeSec);
      kernel[n] = val.clamp(-32768.0, 32767.0).round();
    }
    return kernel;
  }

  /// Renders a looped PCM buffer for a step pattern.
  ///
  /// If [activeSteps] is null, all steps default to active (e.g. 4 clicks for 4 steps).
  Int16List renderPatternPcm({
    required double bpm,
    required int stepCount,
    List<bool>? activeSteps,
    double clickFreq = 2000.0,
    double amplitude = 0.8,
  }) {
    final totalSamples = loopLengthSamples(stepCount, bpm);
    final buffer = Int16List(totalSamples);
    final kernel = generateClickKernel(
      frequencyHz: clickFreq,
      amplitude: amplitude,
    );

    for (var step = 0; step < stepCount; step++) {
      final isActive = activeSteps == null || (step < activeSteps.length && activeSteps[step]);
      if (!isActive) continue;

      final onset = onsetSampleForStep(step, bpm);
      for (var k = 0; k < kernel.length; k++) {
        final targetIndex = onset + k;
        if (targetIndex < totalSamples) {
          final mixed = buffer[targetIndex] + kernel[k];
          buffer[targetIndex] = mixed.clamp(-32768, 32767);
        }
      }
    }

    return buffer;
  }

  /// Renders a metronome loop consisting of [beatsPerBar] beats.
  ///
  /// Beat 0 can have a higher accent frequency (e.g. 2500 Hz) than subsequent beats (2000 Hz).
  Int16List renderMetronomePcm({
    required double bpm,
    int beatsPerBar = 4,
    double normalFreq = 2000.0,
    double accentFreq = 2500.0,
    double amplitude = 0.8,
  }) {
    final totalSteps = beatsPerBar * stepsPerBeat;
    final totalSamples = loopLengthSamples(totalSteps, bpm);
    final buffer = Int16List(totalSamples);

    final normalKernel = generateClickKernel(
      frequencyHz: normalFreq,
      amplitude: amplitude,
    );
    final accentKernel = generateClickKernel(
      frequencyHz: accentFreq,
      amplitude: amplitude,
    );

    for (var beat = 0; beat < beatsPerBar; beat++) {
      final stepIndex = beat * stepsPerBeat;
      final onset = onsetSampleForStep(stepIndex, bpm);
      final kernel = (beat == 0) ? accentKernel : normalKernel;

      for (var k = 0; k < kernel.length; k++) {
        final targetIndex = onset + k;
        if (targetIndex < totalSamples) {
          final mixed = buffer[targetIndex] + kernel[k];
          buffer[targetIndex] = mixed.clamp(-32768, 32767);
        }
      }
    }

    return buffer;
  }

  /// Wraps 16-bit mono PCM samples into a standard 44-byte RIFF/WAVE container.
  static Uint8List encodeWav(Int16List pcmSamples, {int sampleRate = defaultSampleRate}) {
    const numChannels = 1;
    const bitsPerSample = 16;
    final byteRate = sampleRate * numChannels * (bitsPerSample ~/ 8);
    final blockAlign = numChannels * (bitsPerSample ~/ 8);
    final dataSize = pcmSamples.length * 2;
    final fileSize = 36 + dataSize;

    final bytes = Uint8List(44 + dataSize);
    final bdata = ByteData.sublistView(bytes);

    // RIFF header
    bytes.setRange(0, 4, 'RIFF'.codeUnits);
    bdata.setUint32(4, fileSize, Endian.little);
    bytes.setRange(8, 12, 'WAVE'.codeUnits);

    // fmt subchunk
    bytes.setRange(12, 16, 'fmt '.codeUnits);
    bdata.setUint32(16, 16, Endian.little); // Subchunk1Size for PCM
    bdata.setUint16(20, 1, Endian.little); // AudioFormat: 1 = PCM
    bdata.setUint16(22, numChannels, Endian.little);
    bdata.setUint32(24, sampleRate, Endian.little);
    bdata.setUint32(28, byteRate, Endian.little);
    bdata.setUint16(32, blockAlign, Endian.little);
    bdata.setUint16(34, bitsPerSample, Endian.little);

    // data subchunk
    bytes.setRange(36, 40, 'data'.codeUnits);
    bdata.setUint32(40, dataSize, Endian.little);

    // PCM samples (little endian 16-bit)
    final pcmBytes = pcmSamples.buffer.asUint8List(
      pcmSamples.offsetInBytes,
      pcmSamples.lengthInBytes,
    );
    bytes.setRange(44, 44 + dataSize, pcmBytes);

    return bytes;
  }

  /// Renders a pattern as an [AudioBuffer] with WAV bytes.
  AudioBuffer renderPatternBuffer({
    required double bpm,
    required int stepCount,
    List<bool>? activeSteps,
    double clickFreq = 2000.0,
    double amplitude = 0.8,
  }) {
    final pcm = renderPatternPcm(
      bpm: bpm,
      stepCount: stepCount,
      activeSteps: activeSteps,
      clickFreq: clickFreq,
      amplitude: amplitude,
    );
    final wavBytes = encodeWav(pcm, sampleRate: sampleRate);
    final durationUs = (pcm.length * 1000000 / sampleRate).round();

    return AudioBuffer(
      wavBytes: wavBytes,
      pcmSamples: pcm,
      sampleRate: sampleRate,
      totalSamples: pcm.length,
      duration: Duration(microseconds: durationUs),
    );
  }

  /// Renders a metronome as an [AudioBuffer] with WAV bytes.
  AudioBuffer renderMetronomeBuffer({
    required double bpm,
    int beatsPerBar = 4,
    double normalFreq = 2000.0,
    double accentFreq = 2500.0,
    double amplitude = 0.8,
  }) {
    final pcm = renderMetronomePcm(
      bpm: bpm,
      beatsPerBar: beatsPerBar,
      normalFreq: normalFreq,
      accentFreq: accentFreq,
      amplitude: amplitude,
    );
    final wavBytes = encodeWav(pcm, sampleRate: sampleRate);
    final durationUs = (pcm.length * 1000000 / sampleRate).round();

    return AudioBuffer(
      wavBytes: wavBytes,
      pcmSamples: pcm,
      sampleRate: sampleRate,
      totalSamples: pcm.length,
      duration: Duration(microseconds: durationUs),
    );
  }
}
