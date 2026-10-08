import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import '../domain/audio_buffer.dart';
import '../domain/kit.dart';
import '../domain/pattern.dart';
import '../domain/sequence.dart';
import '../domain/voice.dart';
import 'synth_timing.dart';
import 'voice_renderer.dart';
import 'wav_encoder.dart';

/// Parameter object passed into compute isolates when rendering sequences.
@immutable
class SequenceRenderParams {
  final Sequence sequence;
  final Map<String, Pattern> patterns;
  final int sampleRate;
  final List<Voice> voices;
  final String? kitId;

  const SequenceRenderParams({
    required this.sequence,
    required this.patterns,
    this.sampleRate = SynthTiming.defaultSampleRate,
    this.voices = defaultVoices,
    this.kitId,
  });
}

Float32List _computeRenderSequence(SequenceRenderParams params) {
  final renderer = PatternRenderer.withSampleRate(params.sampleRate);
  return renderer.renderSequence(
    params.sequence,
    params.patterns,
    voices: params.voices,
    kitId: params.kitId,
  );
}

AudioBuffer _computeRenderSequenceBuffer(SequenceRenderParams params) {
  final renderer = PatternRenderer.withSampleRate(params.sampleRate);
  return renderer.renderSequenceBuffer(
    params.sequence,
    params.patterns,
    voices: params.voices,
    kitId: params.kitId,
  );
}

/// Pure-Dart audio renderer for 8-track step sequencer patterns and sequences.
///
/// Follows Design D1, D5, D6, D8:
/// - 44100 Hz default sample rate, 4 steps per beat.
/// - Timing calculated via [SynthTiming].
/// - Only renders the first [pattern.stepCount] steps (steps beyond are ignored).
/// - Each active step triggers the track's voice hit.
/// - Deterministic synthesis across all tracks (seeded noise).
/// - Soft limiter ([VoiceRenderer.softLimit]) prevents harsh clipping.
class PatternRenderer {
  /// Maximum duration cap for rendered sequences in seconds (10 minutes).
  static const int maxSequenceDurationSeconds = 600;

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

  /// Renders a [Pattern] into a [Float32List] of normalized mono audio (-1.0 to 1.0).
  Float32List renderFloat32(
    Pattern pattern, {
    List<Voice>? voices,
    Kit? kit,
    String? kitId,
    double? bpm,
  }) {
    final effectiveVoices = kit?.voices ?? voices ?? defaultVoices;
    final effectiveKitId = kit?.id ?? kitId;
    final effectiveBpm = bpm ?? pattern.tempoBpm.toDouble();
    final stepCount = pattern.stepCount;
    final totalSamples = timing.loopLengthSamples(stepCount, effectiveBpm);

    if (totalSamples <= 0) {
      return Float32List(0);
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

      final voice = track < effectiveVoices.length
          ? effectiveVoices[track]
          : defaultVoices[track % defaultVoices.length];
      final hit = voiceRenderer.renderVoice(
        voice,
        trackIndex: track,
        kitId: effectiveKitId,
      );

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

    final floats = Float32List(totalSamples);
    for (var i = 0; i < totalSamples; i++) {
      floats[i] = VoiceRenderer.softLimit(mixBuffer[i]);
    }
    return floats;
  }

  /// Renders a [Pattern] into an [Int16List] of 16-bit mono PCM audio.
  Int16List renderPcm(
    Pattern pattern, {
    List<Voice>? voices,
    Kit? kit,
    String? kitId,
    double? bpm,
  }) {
    final floats = renderFloat32(
      pattern,
      voices: voices,
      kit: kit,
      kitId: kitId,
      bpm: bpm,
    );
    final pcm = Int16List(floats.length);
    for (var i = 0; i < floats.length; i++) {
      pcm[i] = (floats[i] * 32767.0).clamp(-32768.0, 32767.0).round();
    }
    return pcm;
  }

  /// Renders a [Pattern] into an [AudioBuffer] including WAV container bytes.
  AudioBuffer renderBuffer(
    Pattern pattern, {
    List<Voice>? voices,
    Kit? kit,
    String? kitId,
    double? bpm,
  }) {
    final effectiveBpm = bpm ?? pattern.tempoBpm.toDouble();
    final pcm = renderPcm(
      pattern,
      voices: voices,
      kit: kit,
      kitId: kitId,
      bpm: effectiveBpm,
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

  /// Resolves an object (either a [Map<String, Pattern>] or [Iterable<Pattern>])
  /// into a [Map<String, Pattern>].
  static Map<String, Pattern> resolvePatternMap(Object patterns) {
    if (patterns is Map<String, Pattern>) {
      return patterns;
    }
    if (patterns is Map) {
      return patterns.map((k, v) => MapEntry(k.toString(), v as Pattern));
    }
    if (patterns is Iterable<Pattern>) {
      return {for (final p in patterns) p.id: p};
    }
    if (patterns is Iterable) {
      return {for (final p in patterns) (p as Pattern).id: p};
    }
    throw ArgumentError.value(
      patterns,
      'patterns',
      'Expected Map<String, Pattern> or Iterable<Pattern>.',
    );
  }

  /// Renders a [Sequence] by concatenating each referenced [Pattern]'s loop
  /// at its native tempo, repeated [SequenceEntry.repeats] times.
  ///
  /// [patterns] can be passed as [Map<String, Pattern>] or [Iterable<Pattern>].
  /// Missing pattern references are skipped gracefully.
  /// The returned buffer is capped at 10 minutes (or [maxSamples]) to prevent OOM.
  Float32List renderSequence(
    Sequence sequence,
    Object patterns, {
    List<Voice>? voices,
    Kit? kit,
    String? kitId,
    int? maxSamples,
  }) {
    final effectiveVoices = kit?.voices ?? voices ?? defaultVoices;
    final effectiveKitId = kit?.id ?? kitId;
    final patternMap = resolvePatternMap(patterns);
    final limit = maxSamples ?? (sampleRate * maxSequenceDurationSeconds);

    final cachedRenders = <String, Float32List>{};
    var totalLength = 0;
    final plan = <Float32List>[];

    for (final entry in sequence.entries) {
      final pattern = patternMap[entry.patternId];
      if (pattern == null) continue;

      final renderedPattern = cachedRenders.putIfAbsent(
        entry.patternId,
        () => renderFloat32(
          pattern,
          voices: effectiveVoices,
          kitId: effectiveKitId,
        ),
      );

      if (renderedPattern.isEmpty) continue;

      for (var r = 0; r < entry.repeats; r++) {
        if (totalLength + renderedPattern.length > limit) {
          final remaining = limit - totalLength;
          if (remaining > 0) {
            plan.add(renderedPattern.sublist(0, remaining));
            totalLength += remaining;
          }
          break;
        }
        plan.add(renderedPattern);
        totalLength += renderedPattern.length;
      }

      if (totalLength >= limit) break;
    }

    final result = Float32List(totalLength);
    var offset = 0;
    for (final chunk in plan) {
      result.setRange(offset, offset + chunk.length, chunk);
      offset += chunk.length;
    }
    return result;
  }

  /// Renders a [Sequence] into an [AudioBuffer] containing 16-bit PCM and WAV header.
  AudioBuffer renderSequenceBuffer(
    Sequence sequence,
    Object patterns, {
    List<Voice>? voices,
    Kit? kit,
    String? kitId,
    int? maxSamples,
  }) {
    final floats = renderSequence(
      sequence,
      patterns,
      voices: voices,
      kit: kit,
      kitId: kitId,
      maxSamples: maxSamples,
    );
    final pcm = Int16List(floats.length);
    for (var i = 0; i < floats.length; i++) {
      pcm[i] = (floats[i] * 32767.0).clamp(-32768.0, 32767.0).round();
    }
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

  /// Offloads [renderSequence] to a background isolate via [compute].
  static Future<Float32List> renderSequenceCompute({
    required Sequence sequence,
    required Object patterns,
    int sampleRate = SynthTiming.defaultSampleRate,
    List<Voice>? voices,
    Kit? kit,
    String? kitId,
  }) {
    final patternMap = resolvePatternMap(patterns);
    return compute(
      _computeRenderSequence,
      SequenceRenderParams(
        sequence: sequence,
        patterns: patternMap,
        sampleRate: sampleRate,
        voices: kit?.voices ?? voices ?? defaultVoices,
        kitId: kit?.id ?? kitId,
      ),
    );
  }

  /// Offloads [renderSequenceBuffer] to a background isolate via [compute].
  static Future<AudioBuffer> renderSequenceBufferCompute({
    required Sequence sequence,
    required Object patterns,
    int sampleRate = SynthTiming.defaultSampleRate,
    List<Voice>? voices,
    Kit? kit,
    String? kitId,
  }) {
    final patternMap = resolvePatternMap(patterns);
    return compute(
      _computeRenderSequenceBuffer,
      SequenceRenderParams(
        sequence: sequence,
        patterns: patternMap,
        sampleRate: sampleRate,
        voices: kit?.voices ?? voices ?? defaultVoices,
        kitId: kit?.id ?? kitId,
      ),
    );
  }
}

/// Alias and extension of [PatternRenderer] representing the general audio synthesis renderer.
class SynthRenderer extends PatternRenderer {
  const SynthRenderer({
    super.sampleRate = SynthTiming.defaultSampleRate,
    super.timing = const SynthTiming(sampleRate: SynthTiming.defaultSampleRate),
    super.voiceRenderer = const VoiceRenderer(sampleRate: SynthTiming.defaultSampleRate),
  });

  factory SynthRenderer.withSampleRate(int sampleRate) {
    return SynthRenderer(
      sampleRate: sampleRate,
      timing: SynthTiming(sampleRate: sampleRate),
      voiceRenderer: VoiceRenderer(sampleRate: sampleRate),
    );
  }
}
