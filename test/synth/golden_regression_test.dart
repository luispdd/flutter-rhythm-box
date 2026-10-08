import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:rhythm_box/domain/pattern.dart';
import 'package:rhythm_box/domain/voice.dart';
import 'package:rhythm_box/synth/pattern_renderer.dart';

/// 64-bit FNV-1a hash of Int16List PCM buffer.
String fnv1a64Pcm(Int16List pcm) {
  final bytes = pcm.buffer.asUint8List();
  var hash = BigInt.parse('14695981039346656037');
  final fnvPrime = BigInt.parse('1099511628211');
  final mask64 = (BigInt.one << 64) - BigInt.one;

  for (var i = 0; i < bytes.length; i++) {
    hash ^= BigInt.from(bytes[i]);
    hash = (hash * fnvPrime) & mask64;
  }
  return hash.toRadixString(16).padLeft(16, '0');
}

Pattern createTestGroove(int bpm) {
  var p = Pattern(tempoBpm: bpm, stepCount: 16);
  // Track 0 (Kick): steps 0, 4, 8, 12
  p = p.toggleStep(0, 0).toggleStep(0, 4).toggleStep(0, 8).toggleStep(0, 12);
  // Track 1 (Low tom): step 14
  p = p.toggleStep(1, 14);
  // Track 2 (Mid perc): step 6
  p = p.toggleStep(2, 6);
  // Track 3 (High perc): step 10
  p = p.toggleStep(3, 10);
  // Track 4 (Low synth): step 2
  p = p.toggleStep(4, 2);
  // Track 5 (High synth): step 7
  p = p.toggleStep(5, 7);
  // Track 6 (Snare): steps 4, 12
  p = p.toggleStep(6, 4).toggleStep(6, 12);
  // Track 7 (Hat): steps 2, 6, 10, 14
  p = p.toggleStep(7, 2).toggleStep(7, 6).toggleStep(7, 10).toggleStep(7, 14);
  return p;
}

void main() {
  group('Golden Regression Baseline (pre-refactor defaultVoices)', () {
    const renderer = PatternRenderer();

    test('60 BPM test groove hash matches pre-refactor golden', () {
      final pattern60 = createTestGroove(60);
      final pcm60 = renderer.renderPcm(pattern60, voices: defaultVoices);
      final hash60 = fnv1a64Pcm(pcm60);
      expect(hash60, equals('1a64e5412592df68'));
    });

    test('120 BPM test groove hash matches pre-refactor golden', () {
      final pattern120 = createTestGroove(120);
      final pcm120 = renderer.renderPcm(pattern120, voices: defaultVoices);
      final hash120 = fnv1a64Pcm(pcm120);
      expect(hash120, equals('20504b3420f5677a'));
    });

    test('180 BPM test groove hash matches pre-refactor golden', () {
      final pattern180 = createTestGroove(180);
      final pcm180 = renderer.renderPcm(pattern180, voices: defaultVoices);
      final hash180 = fnv1a64Pcm(pcm180);
      expect(hash180, equals('23cac0c8d71d8058'));
    });
  });
}
