import 'dart:typed_data';

import '../domain/audio_buffer.dart';
import '../domain/pattern.dart';
import '../domain/voice.dart';
import 'synth_timing.dart';
import 'voice_renderer.dart';
import 'wav_encoder.dart';

/// Pure-Dart audio renderer for 8-track step sequencer patterns.
///
/// Follows Design D1, D5, D6, D8:
/// - 44100 Hz default sample rate, 4 steps per beat.
/// - Timing calculated via [SynthTiming].
/// - Only renders the first [pattern.stepCount] steps (steps beyond are ignored).
/// - Each active step triggers the track's voice hit.
/// - Deterministic synthesis across all tracks (seeded noise).
/// - Soft limiter ([VoiceRenderer.softLimit]) prevents harsh clipping.
class PatternRenderer {
  final int sampleRate;
  final SynthTiming timing;
  final VoiceRenderer voiceRenderer;

  const PatternRenderer({
    this.sampleRate = SynthTiming.defaultSampleRate,
    this.timing = const SynthTiming(sampleRate: SynthTiming.defaultSampleRate),
    this.voiceRenderer = const VoiceRenderer(sampleRate: SynthTiming.defaultSampleRate),
  });

  /// Factory that configures consistent sample rate across components.
  factory PatternRenderer.withSampleRate(int sampleRate) {
    return PatternRenderer(
      sampleRate: sampleRate,
      timing: SynthTiming(sampleRate: sampleRate),
      voiceRenderer: VoiceRenderer(sampleRate: sampleRate),
    );
  }

  /// Renders a [Pattern] into an [Int16List] of 16-bit mono PCM audio.
  Int16List renderPcm(
    Pattern pattern, {
    List<Voice> voices = defaultVoices,
    double? bpm,
  }) {
    final effectiveBpm = bpm ?? pattern.tempoBpm.toDouble();
    final stepCount = pattern.stepCount;
    final totalSamples = timing.loopLengthSamples(stepCount, effectiveBpm);

    if (totalSamples <= 0) {
      return Int16List(0);
    }

    final mixBuffer = Float64List(totalSamples);
    final trackCount = pattern.tracks.length;

    for (var track = 0; track < trackCount; track++) {
      // Check if this track has any active step in the playable range
      var hasActiveStep = false;
      for (var s = 0; s < stepCount; s++) {
        if (pattern.tracks[track][s]) {
          hasActiveStep = true;
          break;
        }
      }
      if (!hasActiveStep) continue;

      final voice = track < voices.length ? voices[track] : defaultVoices[track % defaultVoices.length];
      final hit = voiceRenderer.renderVoice(voice, trackIndex: track);

      for (var s = 0; s < stepCount; s++) {
        if (!pattern.tracks[track][s]) continue;

        final onset = timing.onsetSampleForStep(s, effectiveBpm);
        for (var k = 0; k < hit.length; k++) {
          final target = onset + k;
          if (target >= totalSamples) break;
          mixBuffer[target] += hit[k];
        }
      }
    }

    final pcm = Int16List(totalSamples);
    for (var i = 0; i < totalSamples; i++) {
      final limited = VoiceRenderer.softLimit(mixBuffer[i]);
      pcm[i] = (limited * 32767.0).clamp(-32768.0, 32767.0).round();
    }
    return pcm;
  }

  /// Renders a [Pattern] into an [AudioBuffer] including WAV container bytes.
  AudioBuffer renderBuffer(
    Pattern pattern, {
    List<Voice> voices = defaultVoices,
    double? bpm,
  }) {
    final effectiveBpm = bpm ?? pattern.tempoBpm.toDouble();
    final pcm = renderPcm(pattern, voices: voices, bpm: effectiveBpm);
    final wavBytes = encodeWav(pcm, sampleRate: sampleRate);
    final durationUs = (pcm.length * 1000000 / sampleRate).round();

    return AudioBuffer(
      wavBytes: wavBytes,
      pcmSamples: pcm,
      sampleRate: sampleRate,
      totalSamples: pcm.length,
      duration: Duration(microseconds: durationUs),
      bpm: effectiveBpm,
      stepCount: pattern.stepCount,
    );
  }
}
