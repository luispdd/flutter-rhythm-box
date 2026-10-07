import 'dart:typed_data';

/// Represents an in-memory rendered audio loop buffer.
class AudioBuffer {
  /// The encoded WAV bytes ready for playback by the audio engine.
  final Uint8List wavBytes;

  /// The raw 16-bit PCM audio samples (mono).
  final Int16List pcmSamples;

  /// Sampling frequency in Hz (typically 44100).
  final int sampleRate;

  /// Total number of audio samples in one full loop iteration.
  final int totalSamples;

  /// Nominal duration of one full loop iteration.
  final Duration duration;

  /// Tempo in BPM used when rendering this buffer.
  final double bpm;

  /// Number of sequence steps in this buffer.
  final int stepCount;

  const AudioBuffer({
    required this.wavBytes,
    required this.pcmSamples,
    required this.sampleRate,
    required this.totalSamples,
    required this.duration,
    required this.bpm,
    required this.stepCount,
  });

  @override
  String toString() =>
      'AudioBuffer(bpm: $bpm, steps: $stepCount, samples: $totalSamples, duration: $duration)';
}
