import 'package:flutter_test/flutter_test.dart';
import 'package:rhythm_box/synth/synth_timing.dart';

void main() {
  group('SynthTiming', () {
    const timing = SynthTiming(sampleRate: 44100);

    test('120 BPM for 16 steps produces 88200 samples and exact onset rounding', () {
      const bpm = 120.0;
      const stepCount = 16;

      // samplesPerStep = (44100 * 60) / (120 * 4) = 5512.5
      expect(timing.samplesPerStep(bpm), equals(5512.5));

      final loopLength = timing.loopLengthSamples(stepCount, bpm);
      expect(loopLength, equals(88200));

      final onsets = timing.calculateStepOnsetIndices(stepCount, bpm);
      expect(onsets.length, equals(16));

      for (var i = 0; i < stepCount; i++) {
        expect(onsets[i], equals((i * 5512.5).round()));
        expect(timing.onsetSampleForStep(i, bpm), equals((i * 5512.5).round()));
      }

      // Check first few onsets
      expect(onsets[0], equals(0));
      expect(onsets[1], equals(5513));
      expect(onsets[2], equals(11025));
      expect(onsets[3], equals(16538));
      expect(onsets[15], equals(82688));
    });

    test('130 BPM fractional step length does not accumulate', () {
      const bpm = 130.0;
      const stepCount = 16;

      // samplesPerStep = (44100 * 60) / (130 * 4) = 5088.461538461538
      final samplesPerStep = timing.samplesPerStep(bpm);
      expect(samplesPerStep, closeTo(5088.4615, 0.0001));

      final loopLength = timing.loopLengthSamples(stepCount, bpm);
      final expectedLength = (16 * 44100 * 60 / 130 / 4).round();
      expect(loopLength, equals(expectedLength));
      expect(loopLength, equals(81415));

      final onsets = timing.calculateStepOnsetIndices(stepCount, bpm);
      for (var i = 0; i < stepCount; i++) {
        final expectedOnset = (i * 44100 * 60 / 130 / 4).round();
        expect(onsets[i], equals(expectedOnset));
        expect(timing.onsetSampleForStep(i, bpm), equals(expectedOnset));
      }

      // Check non-accumulating property: the sum of intervals equals loop length
      var totalIntervals = 0;
      for (var i = 0; i < stepCount - 1; i++) {
        totalIntervals += onsets[i + 1] - onsets[i];
      }
      totalIntervals += loopLength - onsets.last;
      expect(totalIntervals, equals(loopLength));
    });

    test('metronome bar length for 7 beats at 100 BPM matches round(7 * 44100 * 60 / 100)', () {
      const bpm = 100.0;
      const beatsPerBar = 7;

      final expected = (7 * 44100 * 60 / 100).round();
      expect(timing.metronomeBarLengthSamples(beatsPerBar, bpm), equals(expected));
      expect(timing.metronomeBarLengthSamples(beatsPerBar, bpm), equals(185220));

      final beatOnsets = timing.calculateBeatOnsetIndices(beatsPerBar, bpm);
      expect(beatOnsets.length, equals(7));
      for (var i = 0; i < beatsPerBar; i++) {
        expect(beatOnsets[i], equals((i * 44100 * 60 / 100).round()));
      }
    });

    test('invalid inputs throw ArgumentError', () {
      expect(() => timing.samplesPerStep(0), throwsArgumentError);
      expect(() => timing.samplesPerStep(-10), throwsArgumentError);
      expect(() => timing.samplesPerBeat(0), throwsArgumentError);
      expect(() => timing.onsetSampleForStep(-1, 120), throwsArgumentError);
      expect(() => timing.onsetSampleForBeat(-1, 120), throwsArgumentError);
      expect(() => timing.loopLengthSamples(0, 120), throwsArgumentError);
      expect(() => timing.loopLengthSamples(-5, 120), throwsArgumentError);
      expect(() => timing.metronomeBarLengthSamples(0, 120), throwsArgumentError);
    });
  });
}
