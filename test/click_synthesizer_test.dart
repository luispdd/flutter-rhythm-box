import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:rhythm_box/synth/click_synthesizer.dart';

void main() {
  group('ClickSynthesizer - Timing & Rounding (Design D2)', () {
    const synth = ClickSynthesizer(sampleRate: 44100);

    test('120 BPM x 4 steps matches exact loop length and onset indices', () {
      const bpm = 120.0;
      const stepCount = 4;

      // At 44100 Hz, 120 BPM, stepsPerBeat = 4:
      // samplesPerStep = (44100 * 60) / (120 * 4) = 5512.5
      expect(synth.calculateSamplesPerStep(bpm), equals(5512.5));

      // Design D2 rounding rule:
      // onset i = round(i * samplesPerStep)
      // step 0: round(0) = 0
      // step 1: round(5512.5) = 5513
      // step 2: round(11025.0) = 11025
      // step 3: round(16537.5) = 16538
      final onsets = synth.calculateOnsetIndices(stepCount, bpm);
      expect(onsets, equals([0, 5513, 11025, 16538]));

      // Loop length = round(4 * 5512.5) = 22050
      final loopLength = synth.loopLengthSamples(stepCount, bpm);
      expect(loopLength, equals(22050));

      // Verify inter-onset intervals
      expect(onsets[1] - onsets[0], equals(5513));
      expect(onsets[2] - onsets[1], equals(5512));
      expect(onsets[3] - onsets[2], equals(5513));
      // Distance from final step onset to loop wrap (onset 0 of next loop)
      expect(loopLength - onsets[3], equals(5512));
    });

    test('Fractional step length (127 BPM x 4 steps) matches rounding rule', () {
      const bpm = 127.0;
      const stepCount = 4;

      // At 44100 Hz, 127 BPM, stepsPerBeat = 4:
      // samplesPerStep = 2646000 / 508 ≈ 5208.661417322835
      final samplesPerStep = synth.calculateSamplesPerStep(bpm);
      expect(samplesPerStep, closeTo(5208.6614, 0.0001));

      final onsets = synth.calculateOnsetIndices(stepCount, bpm);
      expect(onsets[0], equals(0));
      expect(onsets[1], equals((1 * samplesPerStep).round()));
      expect(onsets[1], equals(5209));
      expect(onsets[2], equals((2 * samplesPerStep).round()));
      expect(onsets[2], equals(10417));
      expect(onsets[3], equals((3 * samplesPerStep).round()));
      expect(onsets[3], equals(15626));

      // Loop length
      final loopLength = synth.loopLengthSamples(stepCount, bpm);
      expect(loopLength, equals((4 * samplesPerStep).round()));
      expect(loopLength, equals(20835));

      // Verify that individual intervals sum exactly to loop length
      final ioi0 = onsets[1] - onsets[0];
      final ioi1 = onsets[2] - onsets[1];
      final ioi2 = onsets[3] - onsets[2];
      final ioi3 = loopLength - onsets[3];
      expect(ioi0 + ioi1 + ioi2 + ioi3, equals(loopLength));
    });

    test('Metronome 4-beat bar loop length and beat onsets match D2 rule', () {
      const bpm = 120.0;
      final buffer = synth.renderMetronomeBuffer(bpm: bpm, beatsPerBar: 4);

      // 4 beats at 120 BPM = 2.0 seconds = 88200 samples
      expect(buffer.totalSamples, equals(88200));
      expect(buffer.duration, equals(const Duration(seconds: 2)));

      // Beat onsets are at steps 0, 4, 8, 12
      expect(synth.onsetSampleForStep(0, bpm), equals(0));
      expect(synth.onsetSampleForStep(4, bpm), equals(22050));
      expect(synth.onsetSampleForStep(8, bpm), equals(44100));
      expect(synth.onsetSampleForStep(12, bpm), equals(66150));
    });

    test('WAV encoding generates valid 44-byte RIFF header with correct PCM size', () {
      final pcm = synth.renderPatternPcm(bpm: 120.0, stepCount: 4);
      expect(pcm.length, equals(22050));

      final wav = ClickSynthesizer.encodeWav(pcm, sampleRate: 44100);
      expect(wav.length, equals(44 + 22050 * 2));

      // Check RIFF header magic bytes
      expect(String.fromCharCodes(wav.sublist(0, 4)), equals('RIFF'));
      expect(String.fromCharCodes(wav.sublist(8, 12)), equals('WAVE'));
      expect(String.fromCharCodes(wav.sublist(12, 16)), equals('fmt '));
      expect(String.fromCharCodes(wav.sublist(36, 40)), equals('data'));

      final bdata = ByteData.sublistView(wav);
      // File size in header is total length - 8
      expect(bdata.getUint32(4, Endian.little), equals(wav.length - 8));
      // AudioFormat = 1 (PCM)
      expect(bdata.getUint16(20, Endian.little), equals(1));
      // NumChannels = 1 (Mono)
      expect(bdata.getUint16(22, Endian.little), equals(1));
      // SampleRate = 44100
      expect(bdata.getUint32(24, Endian.little), equals(44100));
      // BitsPerSample = 16
      expect(bdata.getUint16(34, Endian.little), equals(16));
      // Data size = 22050 * 2
      expect(bdata.getUint32(40, Endian.little), equals(22050 * 2));
    });
  });
}
