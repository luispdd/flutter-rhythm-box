import 'package:flutter_test/flutter_test.dart';
import 'package:rhythm_box/domain/pattern.dart';
import 'package:rhythm_box/synth/pattern_renderer.dart';

void main() {
  group('PatternRenderer', () {
    const renderer = PatternRenderer();

    test('exact buffer length at 120 BPM and 130 BPM', () {
      final pattern120 = Pattern(
        tempoBpm: 120,
        stepCount: 16,
      );
      final pcm120 = renderer.renderPcm(pattern120);
      expect(pcm120.length, equals(88200));

      final pattern130 = Pattern(
        tempoBpm: 130,
        stepCount: 16,
      );
      final pcm130 = renderer.renderPcm(pattern130);
      const expected130 = 81415; // round(16 * 44100 * 60 / 130 / 4)
      expect(pcm130.length, equals(expected130));

      final pattern8Steps = Pattern(
        tempoBpm: 120,
        stepCount: 8,
      );
      final pcm8 = renderer.renderPcm(pattern8Steps);
      expect(pcm8.length, equals(44100));
    });

    test('onset indices are respected', () {
      // Create pattern with only track 0 step 1 active
      var pattern = Pattern(tempoBpm: 120, stepCount: 16);
      pattern = pattern.toggleStep(0, 1);

      final pcm = renderer.renderPcm(pattern);
      expect(pcm.length, equals(88200));

      // At 120 BPM, step 0 is 0..5512, step 1 starts at 5513.
      // Samples before step 1 onset (0..5512) must be silence (0).
      for (var i = 0; i < 5513; i++) {
        expect(pcm[i], equals(0),
            reason: 'Sample at $i before step 1 onset should be 0');
      }

      // Step 1 onset starts at 5513, so first sample of hit is 0, but samples shortly after are non-zero
      expect(pcm[5513], equals(0)); // voice attack starts at 0
      var hasSoundAfterOnset = false;
      for (var i = 5514; i < 5514 + 100; i++) {
        if (pcm[i] != 0) {
          hasSoundAfterOnset = true;
          break;
        }
      }
      expect(hasSoundAfterOnset, isTrue);
    });

    test('hidden steps beyond stepCount are ignored during playback', () {
      // Pattern with stepCount 8
      var patternWithHidden = Pattern(tempoBpm: 120, stepCount: 8);
      // Activate step 0, and hidden steps 8, 9, 10, 15
      patternWithHidden = patternWithHidden.toggleStep(0, 0);
      patternWithHidden = patternWithHidden.toggleStep(0, 8);
      patternWithHidden = patternWithHidden.toggleStep(0, 9);
      patternWithHidden = patternWithHidden.toggleStep(1, 12);
      patternWithHidden = patternWithHidden.toggleStep(7, 15);

      var patternWithoutHidden = Pattern(tempoBpm: 120, stepCount: 8);
      patternWithoutHidden = patternWithoutHidden.toggleStep(0, 0);

      final pcmHidden = renderer.renderPcm(patternWithHidden);
      final pcmWithout = renderer.renderPcm(patternWithoutHidden);

      // Loop length must be 8 steps (44100 samples)
      expect(pcmHidden.length, equals(44100));
      expect(pcmWithout.length, equals(44100));

      // Output should be strictly identical because hidden steps are ignored
      final bytesHidden = pcmHidden.buffer.asUint8List();
      final bytesWithout = pcmWithout.buffer.asUint8List();
      expect(bytesHidden, equals(bytesWithout));
    });

    test('all tracks active on all steps stays within 16-bit range without clipped runs', () {
      // Pattern with all 8 tracks active on every step
      var allActivePattern = Pattern(tempoBpm: 120, stepCount: 16);
      for (var t = 0; t < 8; t++) {
        for (var s = 0; s < 16; s++) {
          allActivePattern = allActivePattern.toggleStep(t, s);
        }
      }

      final pcm = renderer.renderPcm(allActivePattern);
      expect(pcm.length, equals(88200));

      var maxRunAtExtreme = 0;
      var currentRun = 0;

      for (var i = 0; i < pcm.length; i++) {
        final val = pcm[i];
        expect(val, inInclusiveRange(-32768, 32767));

        if (val == 32767 || val == -32768) {
          currentRun++;
          if (currentRun > maxRunAtExtreme) {
            maxRunAtExtreme = currentRun;
          }
        } else {
          currentRun = 0;
        }
      }

      // Requirement: no run of more than 3 consecutive samples sits at a clipped extreme
      expect(maxRunAtExtreme, lessThanOrEqualTo(3),
          reason: 'Found run of $maxRunAtExtreme samples at clipped extreme, expected <= 3');
    });

    test('repeated render of pattern containing noise tracks produces byte-identical PCM', () {
      var pattern = Pattern(tempoBpm: 120, stepCount: 16);
      // Activate noise tracks 6 and 7
      pattern = pattern.toggleStep(6, 2);
      pattern = pattern.toggleStep(6, 6);
      pattern = pattern.toggleStep(7, 0);
      pattern = pattern.toggleStep(7, 4);
      pattern = pattern.toggleStep(7, 8);
      pattern = pattern.toggleStep(7, 12);

      final pcm1 = renderer.renderPcm(pattern);
      final pcm2 = renderer.renderPcm(pattern);

      expect(pcm1.length, equals(pcm2.length));
      final bytes1 = pcm1.buffer.asUint8List();
      final bytes2 = pcm2.buffer.asUint8List();
      expect(bytes1, equals(bytes2));
    });

    test('renderBuffer returns valid AudioBuffer with WAV bytes', () {
      var pattern = Pattern(tempoBpm: 120, stepCount: 16);
      pattern = pattern.toggleStep(0, 0);

      final buffer = renderer.renderBuffer(pattern);
      expect(buffer.totalSamples, equals(88200));
      expect(buffer.pcmSamples.length, equals(88200));
      expect(buffer.wavBytes.length, equals(44 + 88200 * 2));
      expect(buffer.duration, equals(const Duration(seconds: 2)));
      expect(buffer.stepCount, equals(16));
    });
  });
}
