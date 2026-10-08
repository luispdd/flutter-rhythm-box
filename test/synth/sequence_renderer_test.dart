import 'package:flutter_test/flutter_test.dart';
import 'package:rhythm_box/domain/pattern.dart';
import 'package:rhythm_box/domain/sequence.dart';
import 'package:rhythm_box/synth/synth_renderer.dart';
import 'package:rhythm_box/synth/synth_timing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Sequence Rendering (SynthRenderer)', () {
    const timing = SynthTiming(sampleRate: SynthTiming.defaultSampleRate);
    final renderer = SynthRenderer();

    test('renders sequence [Pattern A x 2, Pattern B x 1] with exact sample length', () {
      final patternA = Pattern(
        id: 'pat-a',
        name: 'Pattern A',
        tempoBpm: 120,
        stepCount: 16,
      );

      final patternB = Pattern(
        id: 'pat-b',
        name: 'Pattern B',
        tempoBpm: 140,
        stepCount: 12,
      );

      final seq = Sequence(
        id: 'seq-1',
        name: 'Test Sequence',
        loop: true,
        entries: [
          SequenceEntry(patternId: 'pat-a', repeats: 2),
          SequenceEntry(patternId: 'pat-b', repeats: 1),
        ],
      );

      final expectedSamplesA = timing.loopLengthSamples(patternA.stepCount, 120.0);
      final expectedSamplesB = timing.loopLengthSamples(patternB.stepCount, 140.0);
      final expectedTotal = (expectedSamplesA * 2) + (expectedSamplesB * 1);

      // Verify with Map<String, Pattern>
      final floatBufferFromMap = renderer.renderSequence(seq, {
        'pat-a': patternA,
        'pat-b': patternB,
      });

      expect(floatBufferFromMap.length, equals(expectedTotal));

      // Verify with List<Pattern>
      final floatBufferFromList = renderer.renderSequence(seq, [patternA, patternB]);
      expect(floatBufferFromList.length, equals(expectedTotal));

      // Content should match between map and list invocation
      expect(floatBufferFromList, equals(floatBufferFromMap));
    });

    test('skips missing pattern references gracefully', () {
      final patternA = Pattern(
        id: 'pat-a',
        name: 'Pattern A',
        tempoBpm: 120,
        stepCount: 16,
      );

      final seq = Sequence(
        id: 'seq-missing',
        name: 'Sequence with deleted pattern',
        loop: true,
        entries: [
          SequenceEntry(patternId: 'pat-a', repeats: 2),
          SequenceEntry(patternId: 'pat-deleted', repeats: 3),
        ],
      );

      final expectedSamplesA = timing.loopLengthSamples(patternA.stepCount, 120.0);
      final expectedTotal = expectedSamplesA * 2;

      final buffer = renderer.renderSequence(seq, {'pat-a': patternA});
      expect(buffer.length, equals(expectedTotal));
    });

    test('empty sequence or all-missing entries returns empty buffer', () {
      final emptySeq = Sequence(entries: []);
      final emptyBuffer = renderer.renderSequence(emptySeq, {});
      expect(emptyBuffer, isEmpty);

      final missingSeq = Sequence(entries: [SequenceEntry(patternId: 'ghost', repeats: 5)]);
      final missingBuffer = renderer.renderSequence(missingSeq, {});
      expect(missingBuffer, isEmpty);
    });

    test('renderSequenceBuffer returns valid AudioBuffer with WAV container bytes', () {
      final pattern = Pattern(
        id: 'p1',
        name: 'P1',
        tempoBpm: 120,
        stepCount: 16,
      );

      final seq = Sequence(
        id: 'seq-buf',
        name: 'AudioBuffer test',
        entries: [SequenceEntry(patternId: 'p1', repeats: 2)],
      );

      final audioBuffer = renderer.renderSequenceBuffer(seq, [pattern]);
      final expectedSamples = timing.loopLengthSamples(16, 120.0) * 2;

      expect(audioBuffer.totalSamples, equals(expectedSamples));
      expect(audioBuffer.pcmSamples.length, equals(expectedSamples));
      expect(audioBuffer.wavBytes.length, equals(44 + expectedSamples * 2));
      expect(audioBuffer.duration.inMicroseconds, equals((expectedSamples * 1000000 / 44100).round()));
    });

    test('enforces max sample cap to prevent unbounded memory usage', () {
      final pattern = Pattern(
        id: 'p1',
        name: 'Slow Pattern',
        tempoBpm: 60,
        stepCount: 16,
      );

      final seq = Sequence(
        id: 'seq-long',
        name: 'Excessive repeats',
        entries: [SequenceEntry(patternId: 'p1', repeats: 99)],
      );

      const cap = 50000;
      final cappedBuffer = renderer.renderSequence(seq, [pattern], maxSamples: cap);
      expect(cappedBuffer.length, equals(cap));
    });

    test('isolate compute wrapper produces identical rendered output', () async {
      final patternA = Pattern(
        id: 'pat-a',
        name: 'Pattern A',
        tempoBpm: 120,
        stepCount: 8,
      );

      final patternB = Pattern(
        id: 'pat-b',
        name: 'Pattern B',
        tempoBpm: 130,
        stepCount: 8,
      );

      final seq = Sequence(
        id: 'seq-compute',
        name: 'Compute test',
        entries: [
          SequenceEntry(patternId: 'pat-a', repeats: 2),
          SequenceEntry(patternId: 'pat-b', repeats: 1),
        ],
      );

      final direct = renderer.renderSequence(seq, [patternA, patternB]);

      final computeFloats = await PatternRenderer.renderSequenceCompute(
        sequence: seq,
        patterns: {'pat-a': patternA, 'pat-b': patternB},
      );

      expect(computeFloats.length, equals(direct.length));
      expect(computeFloats, equals(direct));

      final computeAudioBuffer = await PatternRenderer.renderSequenceBufferCompute(
        sequence: seq,
        patterns: [patternA, patternB],
      );

      expect(computeAudioBuffer.totalSamples, equals(direct.length));
      expect(computeAudioBuffer.pcmSamples.length, equals(direct.length));
    });
  });
}
