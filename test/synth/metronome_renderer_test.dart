import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:rhythm_box/domain/metronome_settings.dart';
import 'package:rhythm_box/domain/voice.dart';
import 'package:rhythm_box/synth/metronome_renderer.dart';

/// Helper to estimate dominant frequency of a PCM sample window using DFT power.
double findDominantFrequency(Int16List samples, int offset, int length, int sampleRate) {
  final windowLength = math.min(length, samples.length - offset);
  if (windowLength <= 0) return 0.0;

  var maxPower = 0.0;
  var dominantFreq = 0.0;

  // Search in steps of 25 Hz from 200 Hz to 3500 Hz
  for (var freq = 200.0; freq <= 3500.0; freq += 25.0) {
    double real = 0.0;
    double imag = 0.0;
    final angleStep = 2.0 * math.pi * freq / sampleRate;

    for (var i = 0; i < windowLength; i++) {
      final sample = samples[offset + i].toDouble();
      final angle = angleStep * i;
      real += sample * math.cos(angle);
      imag -= sample * math.sin(angle);
    }

    final power = real * real + imag * imag;
    if (power > maxPower) {
      maxPower = power;
      dominantFreq = freq;
    }
  }

  return dominantFreq;
}

void main() {
  group('MetronomeRenderer', () {
    const renderer = MetronomeRenderer();

    test('bar length for 2 to 9 beats matches spec rounding rule', () {
      const bpm = 100.0;
      for (var beats = 2; beats <= 9; beats++) {
        final settings = MetronomeSettings(beatsPerBar: beats);
        final pcm = renderer.renderPcm(settings: settings, bpm: bpm);

        final expectedSamples = (beats * 44100 * 60 / bpm).round();
        expect(pcm.length, equals(expectedSamples),
            reason: 'Bar length for $beats beats at $bpm BPM must be $expectedSamples');
      }
    });

    test('accent on: beat 1 dominant frequency near 1.5x pitch, other beats near pitch', () {
      final settings = MetronomeSettings(
        beatsPerBar: 4,
        accent: true,
        pitchHz: 1000.0,
        decayMs: 40.0,
        waveform: Waveform.sine,
      );
      const bpm = 120.0;

      final pcm = renderer.renderPcm(settings: settings, bpm: bpm);

      // Beat 1 (index 0) starts at sample 0
      final beat1Freq = findDominantFrequency(pcm, 0, 1500, 44100);
      expect(beat1Freq, closeTo(1500.0, 50.0),
          reason: 'Beat 1 accent should have dominant frequency near 1500 Hz (1.5 * 1000 Hz)');

      // Beat 2 starts at onset for beat 1
      final beat2Onset = renderer.timing.onsetSampleForBeat(1, bpm);
      final beat2Freq = findDominantFrequency(pcm, beat2Onset, 1500, 44100);
      expect(beat2Freq, closeTo(1000.0, 50.0),
          reason: 'Beat 2 should have dominant frequency near 1000 Hz');

      // Beat 3 starts at onset for beat 2
      final beat3Onset = renderer.timing.onsetSampleForBeat(2, bpm);
      final beat3Freq = findDominantFrequency(pcm, beat3Onset, 1500, 44100);
      expect(beat3Freq, closeTo(1000.0, 50.0),
          reason: 'Beat 3 should have dominant frequency near 1000 Hz');
    });

    test('accent off: all beats have the same dominant frequency', () {
      final settings = MetronomeSettings(
        beatsPerBar: 4,
        accent: false,
        pitchHz: 1000.0,
        decayMs: 40.0,
        waveform: Waveform.sine,
      );
      const bpm = 120.0;

      final pcm = renderer.renderPcm(settings: settings, bpm: bpm);

      final beat1Freq = findDominantFrequency(pcm, 0, 1500, 44100);
      expect(beat1Freq, closeTo(1000.0, 50.0),
          reason: 'Beat 1 with accent off should have dominant frequency near 1000 Hz');

      final beat2Onset = renderer.timing.onsetSampleForBeat(1, bpm);
      final beat2Freq = findDominantFrequency(pcm, beat2Onset, 1500, 44100);
      expect(beat2Freq, closeTo(1000.0, 50.0),
          reason: 'Beat 2 should have dominant frequency near 1000 Hz');

      expect(beat1Freq, equals(beat2Freq));
    });

    test('configured waveforms (triangle and square) synthesize successfully', () {
      for (final wave in [Waveform.triangle, Waveform.square]) {
        final settings = MetronomeSettings(
          beatsPerBar: 4,
          accent: true,
          pitchHz: 800.0,
          waveform: wave,
        );
        final pcm = renderer.renderPcm(settings: settings, bpm: 120.0);
        expect(pcm.length, equals(88200));

        // Beat 1 should be louder/accented near 1.5 * 800 = 1200 Hz
        final beat1Freq = findDominantFrequency(pcm, 0, 1500, 44100);
        expect(beat1Freq, closeTo(1200.0, 100.0));
      }
    });

    test('renderBuffer produces valid AudioBuffer with WAV bytes', () {
      final settings = MetronomeSettings(beatsPerBar: 4);
      final buffer = renderer.renderBuffer(settings: settings, bpm: 120.0);

      expect(buffer.totalSamples, equals(88200));
      expect(buffer.pcmSamples.length, equals(88200));
      expect(buffer.wavBytes.length, equals(44 + 88200 * 2));
      expect(buffer.duration, equals(const Duration(seconds: 2)));
      expect(buffer.bpm, equals(120.0));
      expect(buffer.stepCount, equals(16));
    });
  });
}
