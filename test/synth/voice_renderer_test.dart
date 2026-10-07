import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:rhythm_box/domain/voice.dart';
import 'package:rhythm_box/synth/voice_renderer.dart';

void main() {
  group('VoiceRenderer', () {
    const renderer = VoiceRenderer(sampleRate: 44100);

    test('first sample is 0 for all waveforms', () {
      for (final waveform in Waveform.values) {
        final voice = Voice(
          waveform: waveform,
          startFreqHz: 400.0,
          endFreqHz: 200.0,
          decayMs: 100.0,
          gain: 0.8,
          highpassHz: waveform == Waveform.noise ? 3000.0 : null,
        );
        final samples = renderer.renderVoice(voice, durationSec: 0.05);
        expect(samples[0], equals(0.0),
            reason: 'Waveform ${waveform.name} must start at 0');

        final pcm = renderer.renderVoicePcm(voice, durationSec: 0.05);
        expect(pcm[0], equals(0),
            reason: 'PCM for ${waveform.name} must start at 0');
      }
    });

    test('peak amplitude is reached within 2 ms', () {
      // Test with square and high-frequency sine voices
      final squareVoice = Voice(
        waveform: Waveform.square,
        startFreqHz: 400.0,
        endFreqHz: 400.0,
        decayMs: 90.0,
        gain: 1.0,
      );
      final samples = renderer.renderVoice(squareVoice, durationSec: 0.1);

      // 2 ms at 44100 Hz is 88.2 samples
      const twoMsIndex = (0.002 * 44100);

      // Find the global maximum absolute amplitude
      var globalMax = 0.0;
      var globalMaxIndex = 0;
      for (var i = 0; i < samples.length; i++) {
        final abs = samples[i].abs();
        if (abs > globalMax) {
          globalMax = abs;
          globalMaxIndex = i;
        }
      }

      expect(globalMaxIndex, lessThanOrEqualTo(twoMsIndex.round()));
      expect(globalMax, closeTo(1.0, 0.01));

      // Also check 1000 Hz sine wave
      final sineVoice = Voice(
        waveform: Waveform.sine,
        startFreqHz: 1000.0,
        endFreqHz: 1000.0,
        decayMs: 100.0,
        gain: 1.0,
      );
      final sineSamples = renderer.renderVoice(sineVoice, durationSec: 0.1);
      var sineMax = 0.0;
      var sineMaxIndex = 0;
      for (var i = 0; i < sineSamples.length; i++) {
        final abs = sineSamples[i].abs();
        if (abs > sineMax) {
          sineMax = abs;
          sineMaxIndex = i;
        }
      }
      expect(sineMaxIndex, lessThanOrEqualTo(twoMsIndex.round()));
      expect(sineMax, greaterThan(0.95));
    });

    test('decay is below 1 percent of peak at 5x the decay length (500 ms for 100 ms decay)', () {
      final voice = Voice(
        waveform: Waveform.sine,
        startFreqHz: 200.0,
        endFreqHz: 200.0,
        decayMs: 100.0,
        gain: 1.0,
      );

      // Render 510 ms (5x decay is 500 ms)
      final samples = renderer.renderVoice(voice, durationSec: 0.51);

      // Find overall peak amplitude
      var peak = 0.0;
      for (final s in samples) {
        if (s.abs() > peak) peak = s.abs();
      }
      expect(peak, greaterThan(0.5));

      // At 500 ms and beyond (index >= 22050):
      final sampleIndex500ms = (0.5 * 44100).round();
      for (var i = sampleIndex500ms; i < samples.length; i++) {
        final amp = samples[i].abs();
        expect(
          amp,
          lessThan(0.01 * peak),
          reason: 'Sample at index $i ($amp) exceeds 1% of peak (${0.01 * peak})',
        );
      }
    });

    test('noise high-pass spectrum has energy below 1000 Hz at least 20 dB lower than above 7000 Hz', () {
      final voice = Voice(
        waveform: Waveform.noise,
        decayMs: 300.0,
        gain: 1.0,
        highpassHz: 7000.0,
      );

      // Render enough samples for good spectral resolution (N = 4096)
      const n = 4096;
      final samples = renderer.renderVoice(voice, totalSamples: n);

      // Discrete Fourier Transform energy calculation
      var energyBelow1000 = 0.0;
      var energyAbove7000 = 0.0;

      // k = 1 to n/2
      for (var k = 1; k < n ~/ 2; k++) {
        final freq = k * 44100.0 / n;
        if (freq >= 1000.0 && freq <= 7000.0) {
          continue; // outside the two compared bands
        }

        double real = 0.0;
        double imag = 0.0;
        final angleStep = 2.0 * math.pi * k / n;

        for (var i = 0; i < n; i++) {
          final angle = angleStep * i;
          real += samples[i] * math.cos(angle);
          imag -= samples[i] * math.sin(angle);
        }

        final power = real * real + imag * imag;
        if (freq < 1000.0) {
          energyBelow1000 += power;
        } else if (freq > 7000.0) {
          energyAbove7000 += power;
        }
      }

      expect(energyBelow1000, greaterThan(0.0));
      expect(energyAbove7000, greaterThan(0.0));

      final ratioDb = 10.0 * (math.log(energyBelow1000 / energyAbove7000) / math.ln10);

      // Requirement: energy below 1000 Hz is AT LEAST 20 dB LOWER than above 7000 Hz
      // ratioDb = 10*log10(E_low / E_high) <= -20.0
      expect(ratioDb, lessThanOrEqualTo(-20.0),
          reason: 'Energy below 1000 Hz ($energyBelow1000) vs above 7000 Hz ($energyAbove7000) '
              'is $ratioDb dB, expected <= -20 dB');
    });

    test('byte-identical output across two renders including noise voices', () {
      for (var trackIndex = 0; trackIndex < defaultVoices.length; trackIndex++) {
        final voice = defaultVoices[trackIndex];

        final pcm1 = renderer.renderVoicePcm(voice, trackIndex: trackIndex);
        final pcm2 = renderer.renderVoicePcm(voice, trackIndex: trackIndex);

        expect(pcm1.length, equals(pcm2.length));
        final bytes1 = pcm1.buffer.asUint8List();
        final bytes2 = pcm2.buffer.asUint8List();

        expect(bytes1, equals(bytes2),
            reason: 'Track $trackIndex (${voice.waveform.name}) must be byte-identical');
      }
    });

    test('softLimit smoothly limits amplitudes and matches tanh', () {
      expect(VoiceRenderer.softLimit(0.0), equals(0.0));
      expect(VoiceRenderer.softLimit(1.0), closeTo(0.76159, 0.001));
      expect(VoiceRenderer.softLimit(-1.0), closeTo(-0.76159, 0.001));
      expect(VoiceRenderer.softLimit(5.0), closeTo(0.9999, 0.001));
      expect(VoiceRenderer.softLimit(100.0), equals(1.0));
      expect(VoiceRenderer.softLimit(-100.0), equals(-1.0));
    });
  });
}
