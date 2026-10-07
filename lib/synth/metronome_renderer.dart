import 'dart:typed_data';

import '../domain/audio_buffer.dart';
import '../domain/metronome_settings.dart';
import '../domain/voice.dart';
import 'synth_timing.dart';
import 'voice_renderer.dart';
import 'wav_encoder.dart';

/// Pure-Dart audio renderer for metronome click loops.
///
/// Follows Design D1, D5, D8:
/// - 44100 Hz default sample rate.
/// - One bar of [MetronomeSettings.beatsPerBar] beats.
/// - Configured waveform (sine, triangle, square), base pitch, and decay.
/// - Beat 1 (index 0) rendered at [MetronomeSettings.accentPitchHz] (1.5x pitch)
///   when accent is enabled.
/// - Rounding and bar length calculated via [SynthTiming].
class MetronomeRenderer {
  final int sampleRate;
  final SynthTiming timing;
  final VoiceRenderer voiceRenderer;

  const MetronomeRenderer({
    this.sampleRate = SynthTiming.defaultSampleRate,
    this.timing = const SynthTiming(sampleRate: SynthTiming.defaultSampleRate),
    this.voiceRenderer = const VoiceRenderer(sampleRate: SynthTiming.defaultSampleRate),
  });

  /// Factory that configures consistent sample rate across components.
  factory MetronomeRenderer.withSampleRate(int sampleRate) {
    return MetronomeRenderer(
      sampleRate: sampleRate,
      timing: SynthTiming(sampleRate: sampleRate),
      voiceRenderer: VoiceRenderer(sampleRate: sampleRate),
    );
  }

  /// Renders a metronome bar into an [Int16List] of 16-bit mono PCM audio.
  Int16List renderPcm({
    required MetronomeSettings settings,
    required double bpm,
  }) {
    final beatsPerBar = settings.beatsPerBar;
    final totalSamples = timing.metronomeBarLengthSamples(beatsPerBar, bpm);

    if (totalSamples <= 0) {
      return Int16List(0);
    }

    final mixBuffer = Float64List(totalSamples);

    final normalVoice = Voice(
      waveform: settings.waveform,
      startFreqHz: settings.pitchHz,
      endFreqHz: settings.pitchHz,
      decayMs: settings.decayMs,
      gain: 1.0,
    );

    final accentVoice = Voice(
      waveform: settings.waveform,
      startFreqHz: settings.accentPitchHz,
      endFreqHz: settings.accentPitchHz,
      decayMs: settings.decayMs,
      gain: 1.0,
    );

    final normalHit = voiceRenderer.renderVoice(normalVoice);
    final accentHit = settings.accent
        ? voiceRenderer.renderVoice(accentVoice)
        : normalHit;

    for (var beat = 0; beat < beatsPerBar; beat++) {
      final onset = timing.onsetSampleForBeat(beat, bpm);
      final hit = (beat == 0 && settings.accent) ? accentHit : normalHit;

      for (var k = 0; k < hit.length; k++) {
        final target = onset + k;
        if (target >= totalSamples) break;
        mixBuffer[target] += hit[k];
      }
    }

    final pcm = Int16List(totalSamples);
    for (var i = 0; i < totalSamples; i++) {
      final limited = VoiceRenderer.softLimit(mixBuffer[i]);
      pcm[i] = (limited * 32767.0).clamp(-32768.0, 32767.0).round();
    }
    return pcm;
  }

  /// Renders a metronome bar into an [AudioBuffer] including WAV container bytes.
  AudioBuffer renderBuffer({
    required MetronomeSettings settings,
    required double bpm,
  }) {
    final pcm = renderPcm(settings: settings, bpm: bpm);
    final wavBytes = encodeWav(pcm, sampleRate: sampleRate);
    final durationUs = (pcm.length * 1000000 / sampleRate).round();

    return AudioBuffer(
      wavBytes: wavBytes,
      pcmSamples: pcm,
      sampleRate: sampleRate,
      totalSamples: pcm.length,
      duration: Duration(microseconds: durationUs),
      bpm: bpm,
      stepCount: settings.beatsPerBar * SynthTiming.stepsPerBeat,
    );
  }
}
